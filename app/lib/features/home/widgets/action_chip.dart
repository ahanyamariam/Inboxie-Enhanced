import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_model.dart';

class ActionTypeChip extends StatelessWidget {
  final ActionType actionType;

  const ActionTypeChip({super.key, required this.actionType});

  @override
  Widget build(BuildContext context) {
    if (actionType == ActionType.none) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            color: AppColors.accentYellow,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: const TextStyle(
              color: AppColors.accentYellow,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String get _label {
    switch (actionType) {
      case ActionType.directQuestion:
        return 'DIRECT QUESTION';
      case ActionType.deadline:
        return 'DEADLINE';
      case ActionType.waitingReply:
        return 'WAITING REPLY';
      case ActionType.billing:
        return 'BILLING';
      case ActionType.none:
        return '';
    }
  }

  IconData get _icon {
    switch (actionType) {
      case ActionType.directQuestion:
        return Icons.help_outline_rounded;
      case ActionType.deadline:
        return Icons.schedule_rounded;
      case ActionType.waitingReply:
        return Icons.hourglass_empty_rounded;
      case ActionType.billing:
        return Icons.receipt_long_rounded;
      case ActionType.none:
        return Icons.circle;
    }
  }
}