import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_model.dart';
import 'package:app/features/home/widgets/priority_chip.dart';
import 'package:app/features/home/widgets/classification_chip.dart';

class InboxListItem extends StatelessWidget {
  final EmailModel email;
  final VoidCallback? onTap;

  const InboxListItem({super.key, required this.email, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          border: Border(
            bottom: BorderSide(color: AppColors.getDivider(context), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread indicator dot
            if (!email.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue,
                ),
              )
            else
              const SizedBox(width: 18),

            // Email content
            Expanded(
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
                          color: AppColors.getTextPrimary(context),
                          fontSize: 15,
                          fontWeight: email.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
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

                  const SizedBox(height: 6),

                  // Row 2: Subject
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

                  const SizedBox(height: 4),

                  // Row 3: Preview or AI Summary
                  if (email.aiSummary != null && email.aiSummary!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✨ ', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Text(
                            email.aiSummary!,
                            style: TextStyle(
                              color: AppColors.primaryBlue.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      email.preview,
                      style: TextStyle(
                        color: AppColors.getTextSecondary(context),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 10),

                  // Row 4: Chips
                  Wrap(
                    spacing: 8,
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
          ],
        ),
      ),
    );
  }
}
