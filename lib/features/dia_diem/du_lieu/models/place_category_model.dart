import 'package:flutter/material.dart';

class PlaceCategory {
  const PlaceCategory(this.code, this.label, this.icon, this.aliases);

  final String code;
  final String label;
  final IconData icon;

  /// Tên thay thế khi nạp dữ liệu, đã chuẩn hóa chữ thường và bỏ dấu.
  final List<String> aliases;
}
