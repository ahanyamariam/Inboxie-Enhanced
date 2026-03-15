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
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            color: _foregroundColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              color: _foregroundColor,
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
      case ActionType.securityAlert:
        return 'SECURITY ALERT';
      case ActionType.vipSender:
        return 'VIP';
      case ActionType.meeting:
        return 'MEETING / EVENT';
      case ActionType.newsletter:
        return 'NEWSLETTER';
      case ActionType.promotional:
        return 'PROMOTIONAL';
      case ActionType.actionRequired:
        return 'NEEDS ACTION';
      case ActionType.billing:
        return 'BILLING';
      case ActionType.deadline:
        return 'DEADLINE';
      case ActionType.followUp:
        return 'FOLLOW UP';
      case ActionType.tracking:
        return 'TRACKING';
      case ActionType.travel:
        return 'TRAVEL';
      case ActionType.none:
        return '';
    }
  }

  IconData get _icon {
    switch (actionType) {
      case ActionType.securityAlert:
        return Icons.shield_rounded;
      case ActionType.vipSender:
        return Icons.star_rounded;
      case ActionType.meeting:
        return Icons.event_rounded;
      case ActionType.newsletter:
        return Icons.newspaper_rounded;
      case ActionType.promotional:
        return Icons.local_offer_rounded;
      case ActionType.actionRequired:
        return Icons.reply_rounded;
      case ActionType.billing:
        return Icons.receipt_long_rounded;
      case ActionType.deadline:
        return Icons.schedule_rounded;
      case ActionType.followUp:
        return Icons.hourglass_empty_rounded;
      case ActionType.tracking:
        return Icons.local_shipping_rounded;
      case ActionType.travel:
        return Icons.flight_takeoff_rounded;
      case ActionType.none:
        return Icons.circle;
    }
  }

  Color get _backgroundColor {
    switch (actionType) {
      case ActionType.securityAlert:
        return const Color(0xFFD32F2F); // Red
      case ActionType.vipSender:
        return const Color(0xFFF59E0B); // Amber
      case ActionType.meeting:
        return const Color(0xFF7C3AED); // Purple
      case ActionType.newsletter:
        return const Color(0xFF0D9488); // Teal
      case ActionType.promotional:
        return const Color(0xFF9CA3AF); // Gray
      case ActionType.actionRequired:
        return AppColors.primaryBlue;
      case ActionType.billing:
        return const Color(0xFF059669); // Green
      case ActionType.deadline:
        return const Color(0xFFEA580C); // Orange
      case ActionType.followUp:
        return const Color(0xFF6366F1); // Indigo
      case ActionType.tracking:
        return const Color(0xFFFF9800); // Orange
      case ActionType.travel:
        return const Color(0xFF00BCD4); // Cyan
      case ActionType.none:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    switch (actionType) {
      case ActionType.promotional:
        return Colors.white;
      case ActionType.vipSender:
        return const Color(0xFF78350F); // Dark amber text
      default:
        return Colors.white;
    }
  }
}