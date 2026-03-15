import 'package:flutter/material.dart';

enum ItemCategory {
  vegetableFruit('채소/과일', Color(0xFF4CAF50)),
  meat('육류/수산', Color(0xFFF44336)),
  food('식품', Color(0xFFFF9800)),
  beverage('음료', Color(0xFF2196F3)),
  household('생활용품', Color(0xFF9E9E9E)),
  other('기타', Color(0xFF9C27B0));

  const ItemCategory(this.label, this.color);

  final String label;
  final Color color;

  static ItemCategory fromLabel(String label) {
    return ItemCategory.values.firstWhere(
      (c) => c.label == label,
      orElse: () => ItemCategory.other,
    );
  }
}
