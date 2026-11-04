import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Khu vực app phục vụ: TP. Cao Lãnh, Đồng Tháp. Khung tọa độ gần đúng,
/// chỉnh 4 số dưới đây nếu cần rộng/hẹp hơn.
class CaoLanhArea {
  static const String name = 'TP. Cao Lãnh, Đồng Tháp';
  static const double west = 105.57;
  static const double east = 105.72;
  static const double south = 10.40;
  static const double north = 10.52;

  static bool contains(LatLng p) =>
      p.latitude >= south &&
      p.latitude <= north &&
      p.longitude >= west &&
      p.longitude <= east;
}

class GeoResult {
  const GeoResult(this.label, this.position);

  final String label;
  final LatLng position;
}

abstract interface class GeocodingService {
  /// Tìm địa chỉ trong [CaoLanhArea]. Ném lỗi khi không gọi được dịch vụ.
  Future<List<GeoResult>> search(String query);
}

/// Dùng Nominatim (OpenStreetMap). Quy định của họ: tối đa 1 yêu cầu/giây và
/// không tìm khi đang gõ, nên chỉ tìm khi người dùng bấm tìm.
class NominatimGeocodingService implements GeocodingService {
  NominatimGeocodingService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<GeoResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': q,
      'limit': '8',
      'countrycodes': 'vn',
      'accept-language': 'vi',
      // viewbox = trái,trên,phải,dưới; bounded=1: chỉ trả kết quả trong khung.
      'viewbox':
          '${CaoLanhArea.west},${CaoLanhArea.north},${CaoLanhArea.east},${CaoLanhArea.south}',
      'bounded': '1',
    });
    final response = await _client
        .get(
          uri,
          // Trình duyệt không cho đặt User-Agent nên bỏ qua trên web.
          headers: kIsWeb ? null : const {'User-Agent': 'vn.diadiem.quanhday'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Geocoding lỗi ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];
    final results = <GeoResult>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final lat = double.tryParse('${item['lat']}');
      final lon = double.tryParse('${item['lon']}');
      final label = '${item['display_name'] ?? ''}'.trim();
      if (lat == null || lon == null || label.isEmpty) continue;
      final point = LatLng(lat, lon);
      if (CaoLanhArea.contains(point)) results.add(GeoResult(label, point));
    }
    return results;
  }
}
