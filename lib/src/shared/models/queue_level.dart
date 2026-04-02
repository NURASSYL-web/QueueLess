import 'package:flutter/material.dart';
import 'package:queue/src/core/constants/app_colors.dart';

enum QueueLevel {
  short('short', 'Short', 3, AppColors.green),
  medium('medium', 'Medium', 10, AppColors.yellow),
  long('long', 'Long', 20, AppColors.red);

  const QueueLevel(this.value, this.label, this.minutes, this.color);

  final String value;
  final String label;
  final int minutes;
  final Color color;

  static QueueLevel fromValue(String value) {
    return QueueLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => QueueLevel.medium,
    );
  }

  static QueueLevel fromMinutes(num minutes) {
    if (minutes <= 5) return QueueLevel.short;
    if (minutes <= 15) return QueueLevel.medium;
    return QueueLevel.long;
  }
}
