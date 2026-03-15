import 'package:flutter/material.dart';

enum Priority { urgent, important, low, action }

enum ActionType {
  securityAlert,   // OTP, password reset, 2FA
  vipSender,       // From VIP list
  meeting,         // Calendar, event, invite
  newsletter,      // Newsletter digest
  promotional,     // Marketing, sales, offers
  actionRequired,  // Needs a reply or action
  billing,         // Invoice, receipt, payment
  deadline,        // Due date, deadline detected
  followUp,        // Waiting for reply
  none,            // No action tag
}

class EmailModel {
  final String id;
  final String senderName;
  final String senderInitials;
  final String subject;
  final String preview;
  final String threadId;
  final DateTime timestamp;
  final Priority priority;
  final ActionType actionType;
  final bool isRead;
  final Color? avatarColor;
  final String? avatarUrl;
  final List<String> signals;
  final String? classification;
  final String? aiSummary;

  EmailModel({
    required this.id,
    required this.senderName,
    required this.senderInitials,
    required this.subject,
    required this.preview,
    required this.timestamp,
    this.priority = Priority.low,
    this.actionType = ActionType.none,
    required this.threadId,
    this.isRead = false,
    this.avatarColor,
    this.avatarUrl,
    this.signals = const [],
    this.classification,
    this.aiSummary,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}';
  }
}
