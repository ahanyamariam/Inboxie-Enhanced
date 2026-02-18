import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_model.dart';

class RecentEmailItem extends StatelessWidget {
  final EmailModel email;
  final VoidCallback? onTap;

  const RecentEmailItem({super.key, required this.email, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.getCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBackground(context), width: 1),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: email.avatarColor ?? AppColors.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.getDivider(context),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  email.senderInitials,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and Subject
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email.senderName,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.subject,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Time
            Text(
              email.timeAgo,
              style: TextStyle(
                color: AppColors.getTextMuted(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
