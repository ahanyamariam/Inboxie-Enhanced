import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_model.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/features/home/screens/email_details_screen.dart';
import 'package:app/features/home/widgets/priority_chip.dart';
import 'package:app/features/home/widgets/classification_chip.dart';

class BucketDetailPage extends StatefulWidget {
  final String bucketId;
  final String bucketName;
  final IconData bucketIcon;
  final String accessToken;
  final String userEmail;

  const BucketDetailPage({
    super.key,
    required this.bucketId,
    required this.bucketName,
    required this.bucketIcon,
    required this.accessToken,
    required this.userEmail,
  });

  @override
  State<BucketDetailPage> createState() => _BucketDetailPageState();
}

class _BucketDetailPageState extends State<BucketDetailPage> {
  final StorageService _storage = StorageService();
  bool _isLoading = true;
  List<EmailModel> _emails = [];

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    setState(() => _isLoading = true);
    try {
      final rawEmails = await _storage.getEmailsByBucket(widget.bucketId);
      setState(() {
        _emails = rawEmails.map(_dbToEmailModel).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  EmailModel _dbToEmailModel(Map<String, dynamic> data) {
    final senderName = data['senderName'] ?? 'Unknown Sender';
    final senderInitials = _getInitials(senderName);

    Priority priority;
    final label = data['priorityLabel'] as String? ?? 'low';
    final int score = data['priorityScore'] ?? 0;
    switch (label) {
      case 'urgent': priority = Priority.urgent; break;
      case 'important': priority = Priority.important; break;
      case 'normal': priority = Priority.action; break;
      default:
        if (score >= 50) priority = Priority.urgent;
        else if (score >= 25) priority = Priority.important;
        else if (score >= 10) priority = Priority.action;
        else priority = Priority.low;
    }

    final signalsRaw = (data['signals'] as String?) ?? '';
    final signalsList = signalsRaw.isNotEmpty
        ? signalsRaw.split('||').where((s) => s.isNotEmpty).toList()
        : <String>[];
    ActionType type = _signalsToActionType(signalsList, data['bucket'] as String? ?? '');

    final avatarColors = [
      AppColors.primaryBlue,
      const Color(0xFFF2CB04),
      const Color(0xFF1565C0),
      const Color(0xFF0D47A1),
    ];

    return EmailModel(
      id: data['id'] ?? '',
      threadId: data['thread_id'] ?? '',
      senderName: senderName,
      senderInitials: senderInitials,
      subject: data['subject'] ?? '(No Subject)',
      preview: data['snippet'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      priority: priority,
      actionType: type,
      isRead: (data['isRead'] ?? 0) == 1,
      avatarColor: avatarColors[(data['id'] ?? '').hashCode.abs() % avatarColors.length],
      signals: signalsList,
      classification: data['label'],
    );
  }

  ActionType _signalsToActionType(List<String> signals, String bucket) {
    if (signals.any((s) => s.contains('Security'))) return ActionType.securityAlert;
    if (signals.any((s) => s.contains('VIP'))) return ActionType.vipSender;
    if (signals.any((s) => s.contains('Calendar') || s.contains('Meeting'))) return ActionType.meeting;
    if (signals.any((s) => s.contains('Finance') || s.contains('Transaction'))) return ActionType.billing;
    if (signals.any((s) => s.contains('Action required'))) return ActionType.actionRequired;
    if (signals.any((s) => s.contains('Promotional'))) return ActionType.promotional;
    if (signals.any((s) => s.contains('Muted'))) return ActionType.promotional;
    switch (bucket) {
      case 'needs_reply': return ActionType.actionRequired;
      case 'transactions': return ActionType.billing;
      case 'events': return ActionType.meeting;
      case 'promotions': return ActionType.promotional;
      default: return ActionType.none;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF062E62), const Color(0xFF083E84)]
                    : [const Color(0xFF083E84), const Color(0xFF0a4da3)],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(widget.bucketIcon, color: AppColors.accentYellow, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bucketName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${_emails.length} emails',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Email list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : _emails.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.bucketIcon,
                              size: 64,
                              color: AppColors.getTextMuted(context),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No emails in ${widget.bucketName}',
                              style: TextStyle(
                                color: AppColors.getTextSecondary(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Emails will appear here as they\'re classified',
                              style: TextStyle(
                                color: AppColors.getTextMuted(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEmails,
                        color: AppColors.primaryBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _emails.length,
                          itemBuilder: (context, index) {
                            final email = _emails[index];
                            return _buildEmailTile(email);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTile(EmailModel email) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailDetailScreen(
              messageId: email.id,
              threadId: email.threadId,
              accessToken: widget.accessToken,
            ),
          ),
        ).then((_) => _loadEmails());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: email.isRead
                ? AppColors.getDivider(context)
                : AppColors.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: email.avatarColor ?? AppColors.primaryBlue,
              ),
              child: Center(
                child: Text(
                  email.senderInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email.senderName,
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontSize: 15,
                            fontWeight: email.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        email.timeAgo,
                        style: TextStyle(
                          color: AppColors.getTextMuted(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.subject,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 14,
                      fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.preview,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PriorityChip(priority: email.priority),
                      if (email.classification != null)
                        ClassificationChip(labelId: email.classification!),
                    ],
                  ),
                ],
              ),
            ),

            // Unread indicator
            if (!email.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
