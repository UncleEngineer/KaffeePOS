import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String title;
  final String code;
  final String colorCode;

  Category({
    this.id,
    required this.title,
    required this.code,
    required this.colorCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'color_code': colorCode,
    };
  }

  static Category fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      title: map['title'],
      code: map['code'],
      colorCode: map['color_code'],
    );
  }

  Color get color {
    try {
      // Remove # if present and convert to Color
      String hex = colorCode.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if not present
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue; // Default color if parsing fails
    }
  }
}