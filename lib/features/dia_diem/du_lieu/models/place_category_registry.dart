import '../../../../core/utils/text_utils.dart';
import 'loai_dia_diem/ca_phe.dart';
import 'loai_dia_diem/ben_xe.dart';
import 'loai_dia_diem/khac.dart';
import 'loai_dia_diem/mua_sam.dart';
import 'loai_dia_diem/nha_tro.dart';
import 'loai_dia_diem/quan_an.dart';
import 'loai_dia_diem/truong_hoc.dart';
import 'loai_dia_diem/vui_choi.dart';
import 'place_category_model.dart';

/// Danh sách loại địa điểm theo thứ tự hiển thị trong bộ lọc.
const placeCategories = <PlaceCategory>[
  quanAnCategory,
  caPheCategory,
  truongHocCategory,
  nhaTroCategory,
  benXeCategory,
  vuiChoiCategory,
  muaSamCategory,
  khacCategory,
];

PlaceCategory categoryOf(String code) {
  final normalizedCode = parseCategoryCode(code);
  return placeCategories.firstWhere(
    (category) => category.code == normalizedCode,
    orElse: () => khacCategory,
  );
}

/// Đổi loại người dùng nhập thành mã lưu trữ; không nhận ra thì trả về `khac`.
String parseCategoryCode(String raw) {
  final key = _normalizeCategoryKey(raw);
  if (key.isEmpty) return khacCategory.code;
  for (final category in [nhaTroCategory, benXeCategory]) {
    if (category.aliases.any((alias) => _normalizeCategoryKey(alias) == key)) {
      return category.code;
    }
  }
  for (final category in placeCategories) {
    if (key == _normalizeCategoryKey(category.code) ||
        key == _normalizeCategoryKey(category.label)) {
      return category.code;
    }
    if (category.aliases.any((alias) => _normalizeCategoryKey(alias) == key)) {
      return category.code;
    }
  }
  return khacCategory.code;
}

String _normalizeCategoryKey(String value) =>
    foldVietnamese(value)
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
