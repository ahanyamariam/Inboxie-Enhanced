import 'package:flutter/material.dart';

enum Priority { urgent, important, low, action }

enum ActionType { directQuestion, deadline, waitingReply, billing, none }

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
