import 'package:flutter/material.dart';

class EmailLabel {
  final String id;
  final String name;
  final String color; // Hex color string
  final List<String> keywords;
  final String bucketId; // Which bucket this label maps to
  final bool isDefault; // System label vs user-created

  const EmailLabel({
    required this.id,
    required this.name,
    required this.color,
    required this.keywords,
    required this.bucketId,
    this.isDefault = false,
  });

  EmailLabel copyWith({
    String? id,
    String? name,
    String? color,
    List<String>? keywords,
    String? bucketId,
    bool? isDefault,
  }) {
    return EmailLabel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      keywords: keywords ?? this.keywords,
      bucketId: bucketId ?? this.bucketId,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'keywords': keywords,
        'bucketId': bucketId,
        'isDefault': isDefault,
      };

  factory EmailLabel.fromJson(Map<String, dynamic> json) {
    return EmailLabel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#6B7280',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((k) => k as String)
              .toList() ??
          [],
      bucketId: json['bucketId'] ?? 'updates',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Color get displayColor {
    String hex = color.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// Check if an email matches this label based on keywords
  bool matches(String subject, String snippet) {
    if (keywords.isEmpty) return false;
    final subjectLower = subject.toLowerCase();
    final snippetLower = snippet.toLowerCase();
    return keywords.any(
      (kw) => subjectLower.contains(kw.toLowerCase()) || snippetLower.contains(kw.toLowerCase()),
    );
  }
}

/// Default labels shipped with the app
class DefaultLabels {
  static const List<EmailLabel> all = [
    EmailLabel(
      id: 'security',
      name: 'Security',
      color: '#DC2626',
      keywords: [
        'otp', 'one time password', 'verification code', 'password reset',
        'reset your password', 'login attempt', 'new device login',
        'security alert', 'suspicious activity', 'account locked',
        'two-factor', '2fa', 'authentication code',
      ],
      bucketId: 'important',
      isDefault: true,
    ),
    EmailLabel(
      id: 'finance',
      name: 'Finance',
      color: '#F59E0B',
      keywords: [
        'invoice', 'receipt', 'payment', 'debited', 'credited',
        'transaction', 'order confirmation', 'purchase',
        'subscription renewal', 'billing', 'statement',
      ],
      bucketId: 'transactions',
      isDefault: true,
    ),
    EmailLabel(
      id: 'work',
      name: 'Work',
      color: '#3B82F6',
      keywords: [
        'urgent', 'asap', 'immediately', 'critical', 'action required',
        'important', 'please', 'could you', 'can you', 'let me know',
        'confirm', 'review', 'approve', 'send me', 'your feedback',
        'take a look', 'deadline',
      ],
      bucketId: 'needs_reply',
      isDefault: true,
    ),
    EmailLabel(
      id: 'calendar',
      name: 'Calendar',
      color: '#8B5CF6',
      keywords: [
        'meeting', 'invite', 'calendar', 'schedule', 'appointment',
        'rsvp', 'zoom', 'google meet', 'teams call',
      ],
      bucketId: 'events',
      isDefault: true,
    ),
    EmailLabel(
      id: 'social',
      name: 'Social',
      color: '#EC4899',
      keywords: [
        'liked your', 'commented on', 'mentioned you', 'tagged you',
        'follow', 'friend request', 'connection request', 'endorsed',
        'reacted to', 'shared your',
      ],
      bucketId: 'updates',
      isDefault: true,
    ),
    EmailLabel(
      id: 'marketing',
      name: 'Marketing',
      color: '#F97316',
      keywords: [
        'sale', 'offer', 'discount', '% off', 'limited time', 'deal',
        'shop now', 'buy now', 'exclusive', 'free shipping', 'act fast',
        'clearance', 'promo', 'coupon',
      ],
      bucketId: 'promotions',
      isDefault: true,
    ),
    EmailLabel(
      id: 'newsletter',
      name: 'Newsletter',
      color: '#14B8A6',
      keywords: [
        'newsletter', 'digest', 'weekly roundup', 'monthly update',
        'weekly update', 'daily digest', 'weekly digest',
        'weekly newsletter', 'unsubscribe',
      ],
      bucketId: 'updates',
      isDefault: true,
    ),
    EmailLabel(
      id: 'general',
      name: 'General',
      color: '#9CA3AF',
      keywords: [], // Catch-all for non-personal automated/generic updates
      bucketId: 'updates',
      isDefault: true,
    ),
    EmailLabel(
      id: 'personal',
      name: 'Personal',
      color: '#6B7280',
      keywords: [], // Fallback label — no keywords
      bucketId: 'updates',
      isDefault: true,
    ),
  ];

  /// Classify an email by checking labels in priority order.
  /// Returns the first matching label, or 'personal' as fallback.
  static EmailLabel classify(String subject, String snippet, {List<EmailLabel> customLabels = const []}) {
    // Check custom labels first (user-defined take priority)
    for (final label in customLabels) {
      if (label.matches(subject, snippet)) return label;
    }
    // Then check default labels (skip 'personal' — it's the fallback)
    for (final label in all) {
      if (label.id == 'personal') continue;
      if (label.matches(subject, snippet)) return label;
    }
    // Fallback
    return all.last; // 'personal'
  }
}
