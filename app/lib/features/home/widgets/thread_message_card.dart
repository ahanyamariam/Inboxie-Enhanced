import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_detail_model.dart';
import 'package:app/features/home/widgets/email_body_view.dart';

class ThreadMessageCard extends StatelessWidget {
  final EmailDetailModel message;
  final bool isExpanded;
  final bool isLatest;
  final VoidCallback onTap;
  final VoidCallback? onReply;

  const ThreadMessageCard({
    super.key,
    required this.message,
    required this.isExpanded,
    required this.isLatest,
    required this.onTap,
    this.onReply,
  });

  Color get _avatarColor {
    final colors = [
      AppColors.primaryBlue,
      const Color(0xFFF2CB04),
      const Color(0xFF1565C0),
      const Color(0xFF00796B),
      const Color(0xFFC62828),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
    ];
    return colors[message.fromName.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest
              ? AppColors.primaryBlue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.15),
          width: isLatest ? 2 : 1,
        ),
        boxShadow: isLatest
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  _buildHeader(),
                  
                  // Expanded Content
                  if (isExpanded) ...[
                    const SizedBox(height: 16),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildRecipients(),
                    const SizedBox(height: 16),
                    _buildBody(),
                    if (message.attachments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAttachments(),
                    ],
                    if (onReply != null) ...[
                      const SizedBox(height: 16),
                      _buildQuickReply(),
                    ],
                  ] else ...[
                    // Collapsed: Show snippet
                    const SizedBox(height: 10),
                    Text(
                      message.snippet,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _avatarColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              message.senderInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Sender Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message.fromName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: message.isUnread
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (message.isStarred)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Colors.amber[600],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                message.fromEmail,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // Date & Expand Icon
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isExpanded
                    ? AppColors.primaryBlue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: isExpanded ? AppColors.primaryBlue : AppColors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.withValues(alpha: 0.1),
    );
  }

  Widget _buildRecipients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.to.isNotEmpty)
          _buildRecipientRow('To', message.to.join(', ')),
        if (message.cc.isNotEmpty)
          _buildRecipientRow('Cc', message.cc.join(', ')),
        _buildRecipientRow('Date', message.fullFormattedDate),
      ],
    );
  }

  Widget _buildRecipientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return EmailBodyView(
      plainText: message.bodyPlain,
      htmlContent: message.bodyHtml,
      snippet: message.snippet,
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Attachments (${message.attachments.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: message.attachments.map((attachment) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.filename.length > 20
                            ? '${attachment.filename.substring(0, 17)}...'
                            : attachment.filename,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        attachment.formattedSize,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.download_rounded,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickReply() {
    return GestureDetector(
      onTap: onReply,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.reply_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              'Reply to this message...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}