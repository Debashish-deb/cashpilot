/// Category Spending Model
/// Spending breakdown by category
library;

import 'package:flutter/material.dart';

class CategorySpending {
  final String categoryId;
  final String categoryName;
  final double amount;
  final String? colorHex;
  final String? iconCodePoint;
  final double percentage;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    this.colorHex,
    this.iconCodePoint,
    this.percentage = 0,
  });

  Color get color {
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        return Color(int.parse(colorHex!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }

  IconData get icon {
    if (iconCodePoint != null) {
      try {
        return IconData(int.parse(iconCodePoint!), fontFamily: 'MaterialIcons');
      } catch (e) {
        return Icons.category;
      }
    }
    return Icons.category;
  }

  CategorySpending copyWith({double? percentage}) {
    return CategorySpending(
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount,
      colorHex: colorHex,
      iconCodePoint: iconCodePoint,
      percentage: percentage ?? this.percentage,
    );
  }
}
