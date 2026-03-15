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
  tracking,        // Shipping, delivery, package tracking
  travel,          // Flight, hotel, reservation
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

  /// Map intelligence signals to the most appropriate ActionType.
  /// Priority: Security > VIP > Meeting > Billing > Action > Promotional
  static ActionType determineActionType(List<String> signals, String bucket) {
    if (signals.any((s) => s.contains('Security'))) return ActionType.securityAlert;
    if (signals.any((s) => s.contains('VIP'))) return ActionType.vipSender;
    if (signals.any((s) => s.contains('Calendar') || s.contains('Meeting'))) return ActionType.meeting;
    if (signals.any((s) => s.contains('Shipping') || s.contains('Delivery') || s.contains('Tracking'))) return ActionType.tracking;
    if (signals.any((s) => s.contains('Travel') || s.contains('Flight') || s.contains('Hotel') || s.contains('Booking'))) return ActionType.travel;
    if (signals.any((s) => s.contains('Finance') || s.contains('Transaction'))) return ActionType.billing;
    if (signals.any((s) => s.contains('Action required'))) return ActionType.actionRequired;
    if (signals.any((s) => s.contains('Promotional'))) return ActionType.promotional;
    if (signals.any((s) => s.contains('Muted'))) return ActionType.promotional;

    // Fallback: use bucket if no signal matched
    switch (bucket) {
      case 'needs_reply': return ActionType.actionRequired;
      case 'transactions': return ActionType.billing;
      case 'events': return ActionType.meeting;
      case 'promotions': return ActionType.promotional;
      case 'shipping': return ActionType.tracking;
      case 'travel': return ActionType.travel;
      default: return ActionType.none;
    }
  }
}

