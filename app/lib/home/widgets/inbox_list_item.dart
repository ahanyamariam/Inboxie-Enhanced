import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/home/models/email_model.dart';
import 'package:app/home/widgets/priority_chip.dart';

class InboxListItem extends StatelessWidget {
  final EmailModel email;
  final VoidCallback? onTap;

  const InboxListItem({
    Key? key,
    required this.email,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Sender + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  email.senderName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: email.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                Text(
                  email.timeAgo,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Row 2: Subject
            Text(
              email.subject,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Row 3: Preview
            Text(
              email.preview,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Row 4: Priority Chip
            PriorityChip(priority: email.priority),
          ],
        ),
      ),
    );
  }
}