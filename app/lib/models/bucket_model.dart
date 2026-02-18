import 'package:flutter/material.dart';

enum BucketType { reply, waiting, finance, updates }

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