import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';

class SenderListTile extends StatelessWidget {
  final String email;
  final VoidCallback onRemove;
  final bool isVip;

  const SenderListTile({
    super.key,
    required this.email,
    required this.onRemove,
    this.isVip = true,
  });

  String get _initials {
    final parts = email.split('@').first;
    if (parts.length < 2) return parts.toUpperCase();
    return parts.substring(0, 2).toUpperCase();
  }

  Color get _avatarColor {
    final colors = [
      AppColors.primaryBlue,
      const Color(0xFFF2CB04),
      const Color(0xFF00796B),
      const Color(0xFFC62828),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
    ];
    return colors[email.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(email),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _avatarColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: _avatarColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isVip ? Icons.star_rounded : Icons.volume_off_rounded,
                        size: 14,
                        color: isVip 
                            ? AppColors.accentYellow 
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVip ? 'VIP Sender' : 'Muted',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Remove button
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}