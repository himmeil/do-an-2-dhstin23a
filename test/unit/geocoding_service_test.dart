import 'dart:convert';

import 'package:diadiem_quanh_day/features/tim_kiem/services/geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'giới hạn tìm kiếm trong khung Cao Lãnh và bỏ kết quả ngoài khung',
    () async {
      late Uri requested;
      final client = MockClient((request) async {
        requested = request.url;
        expect(request.url.host, 'nominatim.openstreetmap.org');
        expect(request.url.path, '/search');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode([
              {
                'lat': '10.4571',
                'lon': '105.6332',
                'display_name': 'Trong Cao Lãnh',
              },
              {'lat': '10.8', 'lon': '106.7', 'display_name': 'Ngoài khung'},
            ]),
          ),
          200,
        );
      });
      final results = await NominatimGeocodingService(client: client)
          .search('Nguyễn Huệ');

      expect(requested.queryParameters['bounded'], '1');
      expect(requested.queryParameters['viewbox'], isNotEmpty);
      expect(results.map((r) => r.label), ['Trong Cao Lãnh']);
    },
  );

  test('ô tìm trống thì không gọi mạng', () async {
    final client = MockClient((_) async => throw StateError('không được gọi'));
    expect(
      await NominatimGeocodingService(client: client).search('  '),
      isEmpty,
    );
  });
}
