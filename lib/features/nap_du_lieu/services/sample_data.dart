import 'package:latlong2/latlong.dart';

import '../../dia_diem/du_lieu/models/place.dart';

/// Dữ liệu GIẢ để thử app: rải quanh [center] (cách từ vài trăm mét đến vài km).
/// Tên có tiền tố "[Mẫu]" để dễ nhận ra và xóa sau.
List<Place> buildSamplePlaces(LatLng center) {
  // (tên, mã loại, độ lệch vĩ độ, độ lệch kinh độ) — 0,001° ≈ 110 m.
  const seeds = <(String, String, double, double)>[
    ('Quán cơm gần nhất', 'quan_an', 0.0020, 0.0010),
    ('Cà phê góc phố', 'cafe', -0.0030, 0.0020),
    ('Phở sáng', 'quan_an', 0.0050, -0.0040),
    ('Nhà trọ sinh viên A', 'tro', -0.0060, -0.0050),
    ('Trà sữa trước cổng', 'cafe', 0.0010, -0.0020),
    ('Công viên trung tâm', 'vui_choi', 0.0100, 0.0080),
    ('Cửa hàng tiện lợi', 'mua_sam', -0.0040, 0.0060),
    ('Nhà trọ sinh viên B', 'tro', 0.0120, -0.0100),
    ('Rạp chiếu phim', 'vui_choi', -0.0200, 0.0150),
    ('Siêu thị lớn', 'mua_sam', 0.0250, 0.0100),
    ('Quán bún xa', 'quan_an', -0.0300, -0.0250),
    ('Quán cà phê sách', 'cafe', 0.0350, -0.0200),
  ];
  return [
    for (var i = 0; i < seeds.length; i++)
      Place.create(
        name: '[Mẫu] ${seeds[i].$1}',
        category: seeds[i].$2,
        address: 'Địa chỉ mẫu số ${i + 1} (dữ liệu thử)',
        latitude: center.latitude + seeds[i].$3,
        longitude: center.longitude + seeds[i].$4,
        phone: '',
        hours: '07:00 - 22:00',
      ),
  ];
}
