import 'package:flutter/material.dart';

class LabelConfig {
  // Priority labels
  final String urgentLabel;
  final String importantLabel;
  final String lowLabel;

  // Action labels
  final String needsReplyLabel;
  final String waitingLabel;
  final String noActionLabel;

  // Priority colors (hex strings)
  final String urgentColor;
  final String importantColor;
  final String lowColor;

  // Action colors
  final String needsReplyColor;
  final String waitingColor;
  final String noActionColor;

  const LabelConfig({
    this.urgentLabel = 'Urgent',
    this.importantLabel = 'Important',
    this.lowLabel = 'Low',
    this.needsReplyLabel = 'Needs Reply',
    this.waitingLabel = 'Waiting',
    this.noActionLabel = 'No Action',
    this.urgentColor = '#DC2626',
    this.importantColor = '#F59E0B',
    this.lowColor = '#6B7280',
    this.needsReplyColor = '#EF4444',
    this.waitingColor = '#3B82F6',
    this.noActionColor = '#10B981',
  });

  LabelConfig copyWith({
    String? urgentLabel,
    String? importantLabel,
    String? lowLabel,
    String? needsReplyLabel,
    String? waitingLabel,
    String? noActionLabel,
    String? urgentColor,
    String? importantColor,
    String? lowColor,
    String? needsReplyColor,
    String? waitingColor,
    String? noActionColor,
  }) {
    return LabelConfig(
      urgentLabel: urgentLabel ?? this.urgentLabel,
      importantLabel: importantLabel ?? this.importantLabel,
      lowLabel: lowLabel ?? this.lowLabel,
      needsReplyLabel: needsReplyLabel ?? this.needsReplyLabel,
      waitingLabel: waitingLabel ?? this.waitingLabel,
      noActionLabel: noActionLabel ?? this.noActionLabel,
      urgentColor: urgentColor ?? this.urgentColor,
      importantColor: importantColor ?? this.importantColor,
      lowColor: lowColor ?? this.lowColor,
      needsReplyColor: needsReplyColor ?? this.needsReplyColor,
      waitingColor: waitingColor ?? this.waitingColor,
      noActionColor: noActionColor ?? this.noActionColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'urgentLabel': urgentLabel,
        'importantLabel': importantLabel,
        'lowLabel': lowLabel,
        'needsReplyLabel': needsReplyLabel,
        'waitingLabel': waitingLabel,
        'noActionLabel': noActionLabel,
        'urgentColor': urgentColor,
        'importantColor': importantColor,
        'lowColor': lowColor,
        'needsReplyColor': needsReplyColor,
        'waitingColor': waitingColor,
        'noActionColor': noActionColor,
      };

  factory LabelConfig.fromJson(Map<String, dynamic> json) {
    return LabelConfig(
      urgentLabel: json['urgentLabel'] ?? 'Urgent',
      importantLabel: json['importantLabel'] ?? 'Important',
      lowLabel: json['lowLabel'] ?? 'Low',
      needsReplyLabel: json['needsReplyLabel'] ?? 'Needs Reply',
      waitingLabel: json['waitingLabel'] ?? 'Waiting',
      noActionLabel: json['noActionLabel'] ?? 'No Action',
      urgentColor: json['urgentColor'] ?? '#DC2626',
      importantColor: json['importantColor'] ?? '#F59E0B',
      lowColor: json['lowColor'] ?? '#6B7280',
      needsReplyColor: json['needsReplyColor'] ?? '#EF4444',
      waitingColor: json['waitingColor'] ?? '#3B82F6',
      noActionColor: json['noActionColor'] ?? '#10B981',
    );
  }

  // ============ HELPER METHODS ============

  String getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return urgentLabel;
      case 'important':
        return importantLabel;
      case 'low':
        return lowLabel;
      default:
        return priority;
    }
  }

  String getActionLabel(String action) {
    switch (action.toLowerCase()) {
      case 'needs_reply':
        return needsReplyLabel;
      case 'waiting':
        return waitingLabel;
      case 'no_action':
        return noActionLabel;
      default:
        return action;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return _hexToColor(urgentColor);
      case 'important':
        return _hexToColor(importantColor);
      case 'low':
        return _hexToColor(lowColor);
      default:
        return Colors.grey;
    }
  }

  Color getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'needs_reply':
        return _hexToColor(needsReplyColor);
      case 'waiting':
        return _hexToColor(waitingColor);
      case 'no_action':
        return _hexToColor(noActionColor);
      default:
        return Colors.grey;
    }
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}