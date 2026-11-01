import 'dart:convert';

import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/services/nearby_places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('tải quán cà phê và trường học quanh tâm tìm kiếm', () async {
    late String query;
    final client = MockClient((request) async {
      expect(request.url.host, 'overpass-api.de');
      query = request.bodyFields['data']!;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'lat': 10.457,
                'lon': 105.633,
                'tags': {
                  'amenity': 'cafe',
                  'name': 'Cà phê gần đây',
                  'addr:street': 'Nguyễn Huệ',
                  'contact:phone': '0900000000',
                },
              },
              {
                'type': 'way',
                'id': 2,
                'center': {'lat': 10.458, 'lon': 105.634},
                'tags': {
                  'amenity': 'school',
                  'name': 'Trường gần đây',
                  'opening_hours': '07:00-17:00',
                },
              },
              {
                'type': 'node',
                'id': 3,
                'lat': 10.459,
                'lon': 105.635,
                'tags': {'amenity': 'cafe'},
              },
            ],
          }),
        ),
        200,
      );
    });

    final places = await OverpassNearbyPlacesService(client: client)
        .search(center: const LatLng(10.456, 105.632), radiusMeters: 5000);

    expect(query, contains('around:5000,10.456,105.632'));
    expect(places.map((place) => place.name), [
      'Cà phê gần đây',
      'Trường gần đây',
    ]);
    expect(places.first.category, 'cafe');
    expect(places.first.address, 'Nguyễn Huệ');
    expect(places.first.phone, '0900000000');
    expect(places.last.category, 'truong_hoc');
    expect(places.last.hours, '07:00-17:00');
  });

  test('nêu lỗi khi dịch vụ tìm địa điểm không phản hồi thành công', () async {
    final service = OverpassNearbyPlacesService(
      client: MockClient((_) async => http.Response('busy', 503)),
    );

    await expectLater(
      service.search(center: const LatLng(10.456, 105.632), radiusMeters: 1000),
      throwsA(isA<Exception>()),
    );
  });
}
