import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/home/models/email_model.dart';

class PriorityChip extends StatelessWidget {
  final Priority priority;

  const PriorityChip({Key? key, required this.priority}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _textColor,
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

  Color get _backgroundColor {
    switch (priority) {
      case Priority.urgent:
        return AppColors.chipUrgentBg;
      case Priority.important:
        return AppColors.chipImportantBg;
      case Priority.low:
        return AppColors.chipLowBg;
      case Priority.action:
        return AppColors.chipActionBg;
    }
  }

  Color get _textColor {
    switch (priority) {
      case Priority.urgent:
        return AppColors.chipUrgentText;
      case Priority.important:
        return AppColors.chipImportantText;
      case Priority.low:
        return AppColors.chipLowText;
      case Priority.action:
        return AppColors.chipActionText;
    }
  }
}