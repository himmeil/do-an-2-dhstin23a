import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/utils/geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('1 độ kinh tuyến ở xích đạo ≈ 111,2 km', () {
    final d = distanceMeters(const LatLng(0, 0), const LatLng(0, 1));
    expect(d, closeTo(111195, 300));
  });

  test('cùng một điểm thì khoảng cách bằng 0', () {
    const p = LatLng(10.95, 106.82);
    expect(distanceMeters(p, p), 0);
  });

  test('định dạng khoảng cách', () {
    expect(formatDistance(450), '450 m');
    expect(formatDistance(1500), '1,5 km');
    expect(formatDistance(12400), '12 km');
  });
}
