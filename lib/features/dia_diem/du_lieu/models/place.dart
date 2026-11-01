import 'package:latlong2/latlong.dart';

import '../../../../core/utils/text_utils.dart';

/// Dữ liệu địa điểm dùng chung cho lưu cục bộ và Firestore.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone = '',
    this.hours = '',
  });

  final String id;
  final String name;

  /// Mã loại, xem `placeCategories`.
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;

  /// Giờ mở cửa dạng chữ tự do, ví dụ "07:00 - 22:00".
  final String hours;

  LatLng get latLng => LatLng(latitude, longitude);

  /// Cùng tên + cùng tọa độ thì cùng id, nên nạp lại dữ liệu không bị nhân đôi.
  factory Place.create({
    required String name,
    required String category,
    required String address,
    required double latitude,
    required double longitude,
    String phone = '',
    String hours = '',
  }) => Place(
    id: placeStableId(name, latitude, longitude),
    name: name,
    category: category,
    address: address,
    latitude: latitude,
    longitude: longitude,
    phone: phone,
    hours: hours,
  );

  factory Place.fromMap(String id, Map<String, dynamic> map) => Place(
    id: id,
    name: map['name'] as String? ?? '',
    category: map['category'] as String? ?? 'khac',
    address: map['address'] as String? ?? '',
    latitude: (map['lat'] as num? ?? 0).toDouble(),
    longitude: (map['lng'] as num? ?? 0).toDouble(),
    phone: map['phone'] as String? ?? '',
    hours: map['hours'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'address': address,
    'lat': latitude,
    'lng': longitude,
    'phone': phone,
    'hours': hours,
  };
}

/// Id ổn định từ tên + tọa độ. Dùng số học nhỏ (không nhân số lớn) để cho cùng
/// kết quả trên cả Android, iOS và web.
String placeStableId(String name, double latitude, double longitude) {
  final key =
      '${foldVietnamese(name).trim()}|${latitude.toStringAsFixed(5)}|${longitude.toStringAsFixed(5)}';
  var h1 = 7;
  var h2 = 11;
  for (final unit in key.codeUnits) {
    h1 = (h1 * 31 + unit) % 1000000007;
    h2 = (h2 * 131 + unit) % 998244353;
  }
  return '${h1.toRadixString(16).padLeft(8, '0')}${h2.toRadixString(16).padLeft(8, '0')}';
}
