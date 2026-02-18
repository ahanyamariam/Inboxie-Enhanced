import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/gmail_service.dart';

import 'package:app/models/thread_model.dart';
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

  bool _isLoading = true;
  String? _error;
  ThreadModel? _thread;

  final Set<String> _expandedMessages = {};

  @override
  void initState() {
    super.initState();
    _gmailService = GmailService(accessToken: widget.accessToken);
    _loadThread();
  }

  Future<void> _loadThread() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final threadData = await _gmailService.fetchThread(widget.threadId);
      final thread = ThreadModel.fromGmailApi(threadData);

      // Mark latest message as read
      if (thread.latestMessage.isUnread) {
        await _gmailService.markAsRead(thread.latestMessage.id);
      }

      // Expand the latest message by default
      _expandedMessages.add(thread.latestMessage.id);

      setState(() {
        _thread = thread;
      });
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

  void _showReplySheet({bool replyAll = false}) {
    if (_thread == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComposeSheet(
        mode: replyAll ? ComposeMode.replyAll : ComposeMode.reply,
        replyTo: _thread!.latestMessage,
        threadId: widget.threadId,
        onSend: (to, subject, body) => _sendReply(to, subject, body),
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
        onSend: (to, subject, body) => _sendForward(to, subject, body),
      ),
    );
  }

  Future<void> _sendReply(String to, String subject, String body) async {
    try {
      final latestMessage = _thread!.latestMessage;

      await _gmailService.sendEmail(
        to: to,
        subject: subject.startsWith('Re:') ? subject : 'Re: $subject',
        body: body,
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

  Future<void> _sendForward(String to, String subject, String body) async {
    try {
      await _gmailService.sendEmail(
        to: to,
        subject: subject.startsWith('Fwd:') ? subject : 'Fwd: $subject',
        body: body,
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
        onPressed: () => Navigator.pop(context),
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
          onSelected: (value) {
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
                _gmailService.markAsUnread(widget.messageId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as unread')),
                );
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _thread!.messages.length,
        itemBuilder: (context, index) {
          final message = _thread!.messages[index];
          final isExpanded = _expandedMessages.contains(message.id);
          final isLatest = index == _thread!.messages.length - 1;

          return ThreadMessageCard(
            message: message,
            isExpanded: isExpanded,
            isLatest: isLatest,
            onTap: () => _toggleExpanded(message.id),
            onReply: () {
              // Reply to this specific message
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ComposeSheet(
                  mode: ComposeMode.reply,
                  replyTo: message,
                  threadId: widget.threadId,
                  onSend: (to, subject, body) => _sendReply(to, subject, body),
                ),
              );
            },
          );
        },
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
