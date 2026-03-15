import 'package:flutter/material.dart';

class BucketItem {
  final String id;
  final String name;
  final String icon;
  final bool isVisible;
  final int order;

  const BucketItem({
    required this.id,
    required this.name,
    required this.icon,
    this.isVisible = true,
    this.order = 0,
  });

  BucketItem copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isVisible,
    int? order,
  }) {
    return BucketItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'isVisible': isVisible,
        'order': order,
      };

  factory BucketItem.fromJson(Map<String, dynamic> json) {
    return BucketItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'folder',
      isVisible: json['isVisible'] ?? true,
      order: json['order'] ?? 0,
    );
  }
}

class BucketConfig {
  final List<BucketItem> buckets;

  const BucketConfig({this.buckets = const []});

  BucketConfig copyWith({List<BucketItem>? buckets}) {
    return BucketConfig(buckets: buckets ?? this.buckets);
  }

  Map<String, dynamic> toJson() => {
        'buckets': buckets.map((b) => b.toJson()).toList(),
      };

  factory BucketConfig.fromJson(Map<String, dynamic> json) {
    final bucketsList = json['buckets'] as List<dynamic>?;
    return BucketConfig(
      buckets: bucketsList
              ?.map((b) => BucketItem.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory BucketConfig.defaults() => const BucketConfig(
        buckets: [
          BucketItem(
            id: 'important',
            name: 'Important',
            icon: 'star',
            order: 0,
          ),
          BucketItem(
            id: 'needs_reply',
            name: 'Needs Reply',
            icon: 'reply',
            order: 1,
          ),
          BucketItem(
            id: 'transactions',
            name: 'Transactions',
            icon: 'receipt_long',
            order: 2,
          ),
          BucketItem(
            id: 'events',
            name: 'Events',
            icon: 'calendar_today',
            order: 3,
          ),
          BucketItem(
            id: 'promotions',
            name: 'Promotions',
            icon: 'shopping_cart',
            order: 4,
          ),
          BucketItem(
            id: 'updates',
            name: 'Updates',
            icon: 'notifications',
            order: 5,
          ),
          BucketItem(
            id: 'handled',
            name: 'Handled',
            icon: 'task_alt',
            order: 6,
          ),
        ],
      );

  List<BucketItem> get visibleBuckets {
    final visible = buckets.where((b) => b.isVisible).toList();
    visible.sort((a, b) => a.order.compareTo(b.order));
    return visible;
  }

  List<BucketItem> get sortedBuckets {
    final sorted = List<BucketItem>.from(buckets);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }
}

// Icon mapping helper
class BucketIcons {
  static const Map<String, IconData> iconMap = {
    'reply': Icons.reply_rounded,
    'hourglass_empty': Icons.hourglass_empty_rounded,
    'low_priority': Icons.low_priority_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'star': Icons.star_rounded,
    'work': Icons.work_rounded,
    'person': Icons.person_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'flight': Icons.flight_rounded,
    'attach_money': Icons.attach_money_rounded,
    'calendar_today': Icons.calendar_today_rounded,
    'favorite': Icons.favorite_rounded,
    'folder': Icons.folder_rounded,
    'bookmark': Icons.bookmark_rounded,
    'email': Icons.email_rounded,
    'notifications': Icons.notifications_rounded,
    'task_alt': Icons.task_alt_rounded,
  };

  static IconData getIcon(String iconName) {
    return iconMap[iconName] ?? Icons.label_rounded;
  }

  static List<String> get availableIcons => iconMap.keys.toList();
}