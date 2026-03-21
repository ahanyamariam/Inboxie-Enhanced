import 'package:flutter/material.dart';

enum BucketType { important, reply, transactions, events, promotions, updates, inbox, handled }

class BucketModel {
  final BucketType type;
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;

  BucketModel({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
  });
}