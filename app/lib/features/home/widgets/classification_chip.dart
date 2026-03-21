import 'package:flutter/material.dart';
import 'package:app/models/email_label_model.dart';

class ClassificationChip extends StatelessWidget {
  final String labelId;

  const ClassificationChip({super.key, required this.labelId});

  @override
  Widget build(BuildContext context) {
    // Find label in defaults
    final label = DefaultLabels.all.firstWhere(
      (l) => l.id == labelId,
      orElse: () => DefaultLabels.all.last, // Fallback to 'personal'
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: label.displayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: label.displayColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label.name.toUpperCase(),
        style: TextStyle(
          color: label.displayColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
