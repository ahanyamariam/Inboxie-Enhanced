import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/gmail_service.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/services/ai_service.dart';

import 'package:app/models/thread_model.dart';
import 'package:app/models/email_model.dart';
import 'package:app/features/home/widgets/thread_message_card.dart';
import 'package:app/features/home/widgets/compose_sheet.dart';

class EmailDetailScreen extends StatefulWidget {
  final String messageId;
  final String threadId;
  final String accessToken;
  final String? initialSubject;

  const EmailDetailScreen({
    super.key,
    required this.messageId,
    required this.threadId,
    required this.accessToken,
    this.initialSubject,
  });

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  late GmailService _gmailService;
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  bool _readStateChanged = false;
  String? _error;
  ThreadModel? _thread;
  List<String> _replySuggestions = [];
  bool _loadingSuggestions = false;
  AIService? _aiService;

  final Set<String> _expandedMessages = {};

  @override
  void initState() {
    super.initState();
    _gmailService = GmailService(accessToken: widget.accessToken);
    _initAiService();
    _loadThread();
  }

  Future<void> _initAiService() async {
    final prefs = await SharedPreferences.getInstance();
    _aiService = AIService(prefs: prefs);
  }

  Future<void> _loadThread() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final threadData = await _gmailService.fetchThread(widget.threadId);
      final thread = ThreadModel.fromGmailApi(threadData);

      // Enhance the API thread with our local intelligence data (signals/ActionType)
      for (int i = 0; i < thread.messages.length; i++) {
        final msg = thread.messages[i];
        final localData = await _storage.getEmailById(msg.id);
        if (localData != null) {
          final signalsRaw = localData['signals'] as String? ?? '';
          final signals = signalsRaw.isNotEmpty
              ? signalsRaw.split('||').where((s) => s.isNotEmpty).toList()
              : <String>[];
          final bucket = localData['bucket'] as String? ?? '';
          
          final actionType = EmailModel.determineActionType(signals, bucket);

          // We replace the message with a copied instance containing the actionType
          thread.messages[i] = EmailDetailModel(
            id: msg.id,
            threadId: msg.threadId,
            subject: msg.subject,
            from: msg.from,
            fromEmail: msg.fromEmail,
            fromName: msg.fromName,
            to: msg.to,
            cc: msg.cc,
            date: msg.date,
            bodyPlain: msg.bodyPlain,
            bodyHtml: msg.bodyHtml,
            snippet: msg.snippet,
            attachments: msg.attachments,
            labelIds: msg.labelIds,
            isUnread: msg.isUnread,
            isStarred: msg.isStarred,
            messageIdHeader: msg.messageIdHeader,
            inReplyTo: msg.inReplyTo,
            references: msg.references,
            actionType: actionType,
          );
        }
      }

      // Mark latest message as read (Gmail API + local DB)
      if (thread.latestMessage.isUnread) {
        await _gmailService.markAsRead(thread.latestMessage.id);
      }
      await _storage.markAsRead(widget.messageId);
      _readStateChanged = true;

      // Expand the latest message by default
      _expandedMessages.add(thread.latestMessage.id);

      setState(() {
        _thread = thread;
      });

      // Load AI reply suggestions in background
      _loadReplySuggestions();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleExpanded(String messageId) {
    setState(() {
      if (_expandedMessages.contains(messageId)) {
        _expandedMessages.remove(messageId);
      } else {
        _expandedMessages.add(messageId);
      }
    });
  }

  void _expandAll() {
    if (_thread == null) return;
    setState(() {
      _expandedMessages.addAll(_thread!.messages.map((m) => m.id));
    });
  }

  void _collapseAll() {
    if (_thread == null) return;
    setState(() {
      _expandedMessages.clear();
      _expandedMessages.add(_thread!.latestMessage.id);
    });
  }

  Future<void> _markAsHandled(String messageId) async {
    try {
      await _storage.markAsHandled(messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Marked as handled!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true); // Pop back to inbox
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as handled: $e')),
        );
      }
    }
  }

  void _showReplySheet({bool replyAll = false, String? initialBody}) {
    if (_thread == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComposeSheet(
        mode: replyAll ? ComposeMode.replyAll : ComposeMode.reply,
        replyTo: _thread!.latestMessage,
        threadId: widget.threadId,
        onSend: (to, subject, body, {cc, bcc, isHtml = false, attachments}) => 
            _sendReply(to, subject, body, cc: cc, bcc: bcc, isHtml: isHtml, attachments: attachments),
      ),
    );
  }

  void _showForwardSheet() {
    if (_thread == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComposeSheet(
        mode: ComposeMode.forward,
        replyTo: _thread!.latestMessage,
        onSend: (to, subject, body, {cc, bcc, isHtml = false, attachments}) =>
            _sendForward(to, subject, body, cc: cc, bcc: bcc, isHtml: isHtml, attachments: attachments),
      ),
    );
  }

  Future<void> _sendReply(String to, String subject, String body, {
    String? cc,
    String? bcc,
    bool isHtml = false,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final latestMessage = _thread!.latestMessage;

      await _gmailService.sendEmail(
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject.startsWith('Re:') ? subject : 'Re: $subject',
        body: body,
        isHtml: isHtml,
        attachments: attachments,
        threadId: widget.threadId,
        inReplyTo: latestMessage.messageIdHeader,
        references: latestMessage.references?.isNotEmpty == true
            ? latestMessage.references
            : latestMessage.messageIdHeader,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reply sent successfully!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadThread(); // Reload to show the new message
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _sendForward(String to, String subject, String body, {
    String? cc,
    String? bcc,
    bool isHtml = false,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      await _gmailService.sendEmail(
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject.startsWith('Fwd:') ? subject : 'Fwd: $subject',
        body: body,
        isHtml: isHtml,
        attachments: attachments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email forwarded successfully!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to forward: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      rethrow;
    }
  }

  void _showWhySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFFF2CB04),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Why this needs action',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // TODO: Replace with actual intelligence analysis
            _buildWhyItem(
              Icons.help_outline_rounded,
              'Direct question detected',
              true,
            ),
            _buildWhyItem(Icons.reply_rounded, 'No reply from you yet', true),
            _buildWhyItem(Icons.schedule_rounded, 'Waiting for 2 days', false),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confidence: High',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyItem(IconData icon, String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primaryBlue : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isActive ? AppColors.textPrimary : Colors.grey,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleArchive() async {
    try {
      await _gmailService.archiveMessage(widget.messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Archived'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate change
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to archive: $e')));
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete email?'),
        content: const Text('This will move the email to trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _gmailService.trashMessage(widget.messageId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Moved to trash'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _thread != null ? _buildBottomBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context, _readStateChanged),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _thread?.subject ?? widget.initialSubject ?? 'Email',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_thread != null && _thread!.hasMultipleMessages)
            Text(
              '${_thread!.messageCount} messages in thread',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        // Why button
        IconButton(
          icon: const Icon(Icons.psychology_outlined, size: 22),
          tooltip: 'Why?',
          onPressed: _showWhySheet,
        ),
        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            switch (value) {
              case 'archive':
                _handleArchive();
                break;
              case 'delete':
                _handleDelete();
                break;
              case 'expand_all':
                _expandAll();
                break;
              case 'collapse_all':
                _collapseAll();
                break;
              case 'mark_unread':
                await _gmailService.markAsUnread(widget.messageId);
                await _storage.markAsUnread(widget.messageId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Marked as unread'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  Navigator.pop(context, true);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Archive'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'mark_unread',
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Mark unread'),
                ],
              ),
            ),
            if (_thread != null && _thread!.hasMultipleMessages) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'expand_all',
                child: Row(
                  children: [
                    Icon(Icons.unfold_more, size: 20),
                    SizedBox(width: 12),
                    Text('Expand all'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'collapse_all',
                child: Row(
                  children: [
                    Icon(Icons.unfold_less, size: 20),
                    SizedBox(width: 12),
                    Text('Collapse all'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Loading email...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Failed to load email',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadThread,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_thread == null || _thread!.messages.isEmpty) {
      return const Center(child: Text('No email content found'));
    }

    return RefreshIndicator(
      onRefresh: _loadThread,
      color: AppColors.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thread messages
          ...List.generate(_thread!.messages.length, (index) {
            final message = _thread!.messages[index];
            final isExpanded = _expandedMessages.contains(message.id);
            final isLatest = index == _thread!.messages.length - 1;

            return ThreadMessageCard(
              message: message,
              isExpanded: isExpanded,
              isLatest: isLatest,
              onTap: () => _toggleExpanded(message.id),
              onReply: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ComposeSheet(
                    mode: ComposeMode.reply,
                    replyTo: message,
                    threadId: widget.threadId,
                    onSend: (to, subject, body, {cc, bcc, isHtml = false, attachments}) => 
            _sendReply(to, subject, body, cc: cc, bcc: bcc, isHtml: isHtml, attachments: attachments),
                  ),
                );
              },
            );
          }),

          // Suggested Actions Feature
          if (_thread != null && _thread!.latestMessage.actionType != ActionType.none)
            _buildSuggestedActions(_thread!.latestMessage),

          // AI Reply Suggestions
          if (_loadingSuggestions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Generating reply suggestions...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else if (_replySuggestions.isNotEmpty)
            _buildReplySuggestions(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _BottomActionButton(
                icon: Icons.reply_rounded,
                label: 'Reply',
                isPrimary: true,
                onTap: () => _showReplySheet(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BottomActionButton(
                icon: Icons.reply_all_rounded,
                label: 'Reply All',
                onTap: () => _showReplySheet(replyAll: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BottomActionButton(
                icon: Icons.forward_rounded,
                label: 'Forward',
                onTap: _showForwardSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedActions(EmailDetailModel message) {
    if (message.actionType == ActionType.none) return const SizedBox.shrink();

    final List<Widget> actionChips = [];

    // 1. Meeting / Event
    if (message.actionType == ActionType.meeting) {
      actionChips.add(
        _SuggestedActionChip(
          icon: Icons.edit_calendar_rounded,
          label: 'Add to Calendar',
          color: const Color(0xFF9C27B0), // Purple
          onTap: () async {
            // Create a Google Calendar template URL
            final text = Uri.encodeComponent(message.subject);
            final details = Uri.encodeComponent('From email: ${message.fromName} (${message.fromEmail})');
            final url = Uri.parse('https://calendar.google.com/calendar/render?action=TEMPLATE&text=$text&details=$details');
            try {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open calendar')),
                );
              }
            }
          },
        ),
      );
    }

    // 2. Needs Action / Direct Question / Follow Up
    if (message.actionType == ActionType.actionRequired || 
        message.actionType == ActionType.followUp) {
      actionChips.add(
        _SuggestedActionChip(
          icon: Icons.reply_rounded,
          label: 'Quick Reply',
          color: AppColors.primaryBlue,
          onTap: _showReplySheet,
        ),
      );
    }

    // 3. Billing / Transaction — improved to open PDF or payment link
    if (message.actionType == ActionType.billing) {
      // Check for PDF attachments first
      final pdfAttachment = message.attachments.where(
        (a) => a.mimeType == 'application/pdf' || a.filename.toLowerCase().endsWith('.pdf'),
      );

      if (pdfAttachment.isNotEmpty) {
        actionChips.add(
          _SuggestedActionChip(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Open Invoice (${pdfAttachment.first.formattedSize})',
            color: const Color(0xFFE53935), // Red for PDF
            onTap: () async {
              // Open PDF attachment via Gmail API download
              try {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading ${pdfAttachment.first.filename}...\nPlease wait...')),
                  );
                }
                final attachmentData = await _gmailService.fetchAttachment(
                  message.id,
                  pdfAttachment.first.id,
                );
                if (attachmentData != null && mounted) {
                  // Gmail returns base64url encoded string
                  final base64Str = attachmentData.replaceAll('-', '+').replaceAll('_', '/');
                  final bytes = base64.decode(base64Str);
                  
                  final dir = await getTemporaryDirectory();
                  final file = File('${dir.path}/${pdfAttachment.first.filename}');
                  await file.writeAsBytes(bytes);
                  
                  final result = await OpenFilex.open(file.path);
                  
                  if (mounted && result.type != ResultType.done) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open file: ${result.message}')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to download: $e')),
                  );
                }
              }
            },
          ),
        );
      }

      // Also look for billing/payment links in the email body
      final paymentUrl = _extractUrlByKeywords(
        message.bodyHtml.isNotEmpty ? message.bodyHtml : message.bodyPlain,
        ['pay', 'invoice', 'receipt', 'bill', 'statement', 'payment'],
      );

      if (paymentUrl != null) {
        actionChips.add(
          _SuggestedActionChip(
            icon: Icons.payment_rounded,
            label: 'Open Payment Link',
            color: const Color(0xFF4CAF50), // Green
            onTap: () async {
              try {
                await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open payment link')),
                  );
                }
              }
            },
          ),
        );
      } else if (pdfAttachment.isEmpty) {
        // Fallback: no PDF, no link — generic action
        actionChips.add(
          _SuggestedActionChip(
            icon: Icons.receipt_long_rounded,
            label: 'View Invoice',
            color: const Color(0xFF4CAF50),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice details are in the email body below')),
              );
            },
          ),
        );
      }
    }

    // 4. Tracking / Shipping
    if (message.actionType == ActionType.tracking) {
      final trackingUrl = _extractUrlByKeywords(
        message.bodyHtml.isNotEmpty ? message.bodyHtml : message.bodyPlain,
        ['track', 'shipping', 'delivery', 'carrier', 'package', 'shipment', 'ups', 'fedex', 'dhl', 'usps'],
      );

      actionChips.add(
        _SuggestedActionChip(
          icon: Icons.local_shipping_rounded,
          label: 'Track Package',
          color: const Color(0xFFFF9800), // Orange
          onTap: () async {
            if (trackingUrl != null) {
              try {
                await launchUrl(Uri.parse(trackingUrl), mode: LaunchMode.externalApplication);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open tracking link')),
                  );
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No tracking link found — check email body')),
                );
              }
            }
          },
        ),
      );
    }

    // 5. Travel / Flight / Hotel
    if (message.actionType == ActionType.travel) {
      final travelUrl = _extractUrlByKeywords(
        message.bodyHtml.isNotEmpty ? message.bodyHtml : message.bodyPlain,
        ['check-in', 'checkin', 'boarding', 'itinerary', 'reservation', 'booking', 'flight', 'hotel'],
      );

      actionChips.add(
        _SuggestedActionChip(
          icon: Icons.flight_takeoff_rounded,
          label: travelUrl != null ? 'Check In' : 'View Reservation',
          color: const Color(0xFF00BCD4), // Cyan
          onTap: () async {
            if (travelUrl != null) {
              try {
                await launchUrl(Uri.parse(travelUrl), mode: LaunchMode.externalApplication);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open travel link')),
                  );
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No check-in link found — check email body')),
                );
              }
            }
          },
        ),
      );
    }

    // 6. Universal "Mark Handled"
    actionChips.add(
      _SuggestedActionChip(
        icon: Icons.task_alt_rounded,
        label: 'Mark Handled',
        color: Colors.grey[700]!,
        isOutlined: true,
        onTap: () => _markAsHandled(message.id), 
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 16,
                color: AppColors.accentYellow,
              ),
              const SizedBox(width: 6),
              const Text(
                'Suggested Actions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: actionChips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Extract the first URL from email body whose surrounding text matches any of the given keywords.
  /// Searches both HTML href attributes and plain-text URLs.
  String? _extractUrlByKeywords(String body, List<String> keywords) {
    if (body.isEmpty) return null;

    // 1. Try HTML href links first — look for <a href="URL">...keyword...</a>
    final hrefRegex = RegExp(
      r'<a\s[^>]*href=["\x27]([^"\x27]+)["\x27][^>]*>(.*?)</a>',
      caseSensitive: false,
    );
    for (final match in hrefRegex.allMatches(body)) {
      final url = match.group(1) ?? '';
      final linkText = match.group(2) ?? '';
      final combined = '$url $linkText'.toLowerCase();

      if (url.startsWith('http') && keywords.any((k) => combined.contains(k.toLowerCase()))) {
        return url;
      }
    }

    // 2. Fallback: plain-text URLs near keywords
    final urlRegex = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
    for (final match in urlRegex.allMatches(body)) {
      final url = match.group(0) ?? '';
      // Check a 200-char window around the URL for keyword context
      final start = (match.start - 100).clamp(0, body.length);
      final end = (match.end + 100).clamp(0, body.length);
      final context = body.substring(start, end).toLowerCase();

      if (keywords.any((k) => context.contains(k.toLowerCase()))) {
        return url;
      }
    }

    return null;
  }

  Future<void> _loadReplySuggestions() async {
    if (_aiService == null || _thread == null) return;
    if (!_aiService!.isConfigured) return;

    setState(() => _loadingSuggestions = true);

    try {
      final latest = _thread!.latestMessage;
      final suggestions = await _aiService!.generateReplySuggestions(
        subject: latest.subject,
        content: latest.bodyPlain.isNotEmpty ? latest.bodyPlain : latest.snippet,
      );

      if (mounted) {
        setState(() {
          _replySuggestions = suggestions;
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      print('Failed to load reply suggestions: $e');
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Widget _buildReplySuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'AI Suggested Replies',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._replySuggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _showReplyWithSuggestion(suggestion),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply_rounded,
                          size: 16,
                          color: AppColors.primaryBlue.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showReplyWithSuggestion(String suggestion) {
    if (_thread == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComposeSheet(
        mode: ComposeMode.reply,
        replyTo: _thread!.latestMessage,
        threadId: widget.threadId,
        initialBody: suggestion,
        onSend: (to, subject, body, {cc, bcc, isHtml = false, attachments}) => 
            _sendReply(to, subject, body, cc: cc, bcc: bcc, isHtml: isHtml, attachments: attachments),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? AppColors.primaryBlue
          : AppColors.primaryBlue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _SuggestedActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isOutlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
