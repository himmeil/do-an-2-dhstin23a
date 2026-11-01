import 'package:diadiem_quanh_day/core/utils/text_utils.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bỏ dấu tiếng Việt', () {
    expect(
      foldVietnamese('Cà Phê Đường Nguyễn Huệ'),
      'ca phe duong nguyen hue',
    );
  });

  test('nhận ra loại từ chữ người dùng nhập', () {
    expect(parseCategoryCode('Cà phê'), 'cafe');
    expect(parseCategoryCode('quan_an'), 'quan_an');
    expect(parseCategoryCode('nhà trọ'), 'tro');
    expect(parseCategoryCode(''), 'khac');
    expect(parseCategoryCode('không biết'), 'khac');
  });
}
