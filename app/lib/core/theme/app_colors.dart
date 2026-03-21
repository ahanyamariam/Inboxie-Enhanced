import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (same in both themes)
  static const Color primaryBlue = Color(0xFF083E84);
  static const Color accentYellow = Color(0xFFF2CB04);

  // Light Theme Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color cream = Color(0xFFFAF9F6);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Wave Colors
  static const Color waveYellowLight = Color(0xFFFFF176);
  static const Color waveYellowMedium = Color(0xFFF2CB04);
  static const Color waveYellowDark = Color(0xFFD4A904);

  // Header Gradient Colors
  static const Color headerYellow = Color(0xFFFFF8E1);
  static const Color headerBlue = Color(0xFFE3F2FD);
  static const Color darkHeaderYellow = Color(0xFF2D2A1E);
  static const Color darkHeaderBlue = Color(0xFF1A2633);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ============ THEME-AWARE HELPERS ============

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : Colors.white;
  }

  static List<Color> getHeaderGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [darkHeaderYellow, darkHeaderBlue]
        : [headerYellow, headerBlue];
  }

  static Color getCard(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : Colors.white;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : textPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textSecondary;
  }

  static Color getTextMuted(BuildContext context) {
    return (Theme.of(context).brightness == Brightness.dark
            ? darkTextSecondary
            : textSecondary)
        .withValues(alpha: 0.6);
  }

  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E7EB);
  }

  // ============ PRIORITY COLORS ============

  static Color getPriorityBg(BuildContext context, dynamic priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = priority.toString().split('.').last.toLowerCase();

    switch (p) {
      case 'urgent':
        return primaryBlue;
      case 'important':
        return isDark ? primaryBlue.withValues(alpha: 0.3) : const Color(0xFFFFF8E1);
      case 'low':
        return isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFE3F2FD);
      case 'action':
        return primaryBlue;
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  static Color getPriorityText(BuildContext context, dynamic priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = priority.toString().split('.').last.toLowerCase();

    switch (p) {
      case 'urgent':
        return accentYellow;
      case 'important':
        return isDark ? accentYellow : primaryBlue;
      case 'low':
        return isDark ? Colors.white70 : primaryBlue;
      case 'action':
        return accentYellow;
      default:
        return Colors.grey;
    }
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
