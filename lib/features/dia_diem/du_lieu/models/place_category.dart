import 'package:flutter/material.dart';

import '../../../../core/utils/text_utils.dart';

class PlaceCategory {
  const PlaceCategory(this.code, this.label, this.icon, this.aliases);

  final String code;
  final String label;
  final IconData icon;

  /// Cách gọi khác khi nạp dữ liệu hàng loạt (đã bỏ dấu, chữ thường).
  final List<String> aliases;
}

/// Mã loại lưu cùng mỗi địa điểm.
const placeCategories = <PlaceCategory>[
  PlaceCategory('quan_an', 'Quán ăn', Icons.restaurant_outlined, [
    'an uong',
    'nha hang',
    'food',
  ]),
  PlaceCategory('cafe', 'Cà phê', Icons.local_cafe_outlined, [
    'ca phe',
    'coffee',
    'tra sua',
  ]),
  PlaceCategory('tro', 'Nhà trọ', Icons.home_work_outlined, [
    'nha tro',
    'phong tro',
    'ky tuc xa',
  ]),
  PlaceCategory('vui_choi', 'Vui chơi', Icons.celebration_outlined, [
    'vui choi',
    'giai tri',
    'cong vien',
    'rap phim',
  ]),
  PlaceCategory('mua_sam', 'Mua sắm', Icons.storefront_outlined, [
    'mua sam',
    'cua hang',
    'shop',
    'sieu thi',
    'cho',
  ]),
  PlaceCategory('khac', 'Khác', Icons.place_outlined, []),
];

PlaceCategory categoryOf(String code) => placeCategories.firstWhere(
  (c) => c.code == code,
  orElse: () => placeCategories.last,
);

/// Đổi chữ người dùng nhập ("Cà phê", "cafe", "quan an"...) về mã loại.
/// Không nhận ra thì trả về 'khac'.
String parseCategoryCode(String raw) {
  final key = foldVietnamese(raw).trim();
  if (key.isEmpty) return 'khac';
  for (final c in placeCategories) {
    if (key == c.code || key == foldVietnamese(c.label)) return c.code;
    if (c.aliases.contains(key)) return c.code;
  }
  return 'khac';
}
