import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_model.dart';

class PriorityChip extends StatelessWidget {
  final Priority priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getPriorityBg(context, priority),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: AppColors.getPriorityText(context, priority),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String get _label {
    switch (priority) {
      case Priority.urgent:
        return 'URGENT';
      case Priority.important:
        return 'IMPORTANT';
      case Priority.low:
        return 'LOW';
      case Priority.action:
        return 'ACTION';
    }
  }
}
