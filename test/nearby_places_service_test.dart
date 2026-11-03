import 'dart:convert';

import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/services/nearby_places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('web dùng proxy local và gửi vị trí dạng JSON', () async {
    late String body;
    final client = MockClient((request) async {
      expect(request.url.host, 'localhost');
      expect(request.url.path, '/api/nearby');
      body = request.body;
      return http.Response(jsonEncode({'elements': []}), 200);
    });

    final places = await OverpassNearbyPlacesService(
      client: client,
      webBaseUrl: 'http://localhost:8787',
      useProxy: true,
    ).search(center: const LatLng(10.456, 105.632), radiusMeters: 5000);

    expect(places, isEmpty);
    expect(body, contains('"radiusMeters":5000'));
  });

  test('đọc danh sách snapshot map mà admin có thể chọn', () async {
    final service = OverpassNearbyPlacesService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/admin/map-sources');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'sources': [
                {
                  'source': 'current',
                  'label': 'Địa điểm Cao Lãnh mới',
                  'file': 'dia_diem_cao_lanh.json',
                  'count': 120,
                  'updatedAt': '2026-11-02T10:00:00.000Z',
                  'active': true,
                },
                {
                  'source': 'backup',
                  'label': 'Địa điểm Cao Lãnh cũ',
                  'file': 'backup_dia_diem_cao_lanh.json',
                  'count': 100,
                  'updatedAt': '2026-11-01T10:00:00.000Z',
                  'active': false,
                },
              ],
            }),
          ),
          200,
        );
      }),
      useProxy: true,
    );

    final sources = await service.listMapDataSources();

    expect(sources, hasLength(2));
    expect(sources.first.label, 'Địa điểm Cao Lãnh mới');
    expect(sources.first.active, isTrue);
    expect(sources.last.source, 'backup');
    expect(sources.last.count, 100);
    expect(sources.last.updatedAt, isNotNull);
  });

  test('admin gửi yêu cầu áp dụng snapshot được chọn', () async {
    late String body;
    final service = OverpassNearbyPlacesService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/admin/select-map');
        body = request.body;
        return http.Response(
          jsonEncode({
            'source': 'backup',
            'file': 'backup_dia_diem_cao_lanh.json',
            'count': 100,
          }),
          200,
        );
      }),
      useProxy: true,
    );

    final count = await service.selectMapDataSource('backup');

    expect(body, '{"source":"backup"}');
    expect(count, 100);
  });

  test('phân loại dữ liệu Overpass để dùng chung với bộ lọc', () async {
    final client = MockClient((_) async {
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'lat': 10.456,
                'lon': 105.632,
                'tags': {'name': 'Công viên OSM', 'leisure': 'park'},
              },
              {
                'type': 'node',
                'lat': 10.457,
                'lon': 105.633,
                'tags': {'name': 'Cửa hàng OSM', 'shop': 'supermarket'},
              },
              {
                'type': 'node',
                'lat': 10.458,
                'lon': 105.634,
                'tags': {'name': 'Hotel từ SQL', 'app:category': 'hotel'},
              },
              {
                'type': 'node',
                'lat': 10.459,
                'lon': 105.635,
                'tags': {'name': 'Ký túc xá Cao đẳng', 'app:category': 'khac'},
              },
              {
                'type': 'node',
                'lat': 10.46,
                'lon': 105.636,
                'tags': {'name': 'Công Viên Thiếu Nhi', 'app:category': 'khac'},
              },
              {
                'type': 'node',
                'lat': 10.461,
                'lon': 105.637,
                'tags': {
                  'name': 'Trung Tâm Giáo Dục Thường Xuyên',
                  'app:category': 'khac',
                },
              },
            ],
          }),
        ),
        200,
      );
    });

    final places = await OverpassNearbyPlacesService(
      client: client,
      useProxy: true,
      webBaseUrl: 'http://localhost:8787',
    ).search(center: const LatLng(10.456, 105.632), radiusMeters: 1000);

    expect(places, hasLength(6));
    expect(places[0].category, 'vui_choi');
    expect(places[1].category, 'mua_sam');
    expect(places[2].category, 'tro');
    expect(places[3].category, 'tro');
    expect(places[4].category, 'vui_choi');
    expect(places[5].category, 'truong_hoc');
  });

  test('tìm nhà khách, ký túc xá và bến xe theo thẻ OpenStreetMap', () async {
    SharedPreferences.setMockInitialValues({});
    late String query;
    final service = OverpassNearbyPlacesService(
      client: MockClient((request) async {
        query = request.bodyFields['data']!;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'elements': [
                {
                  'type': 'node',
                  'lat': 10.456,
                  'lon': 105.632,
                  'tags': {
                    'name': 'Nhà khách tỉnh',
                    'app:category': 'yes',
                    'building': 'yes',
                  },
                },
                {
                  'type': 'node',
                  'lat': 10.457,
                  'lon': 105.633,
                  'tags': {'name': 'Ký túc xá B', 'amenity': 'dormitory'},
                },
                {
                  'type': 'way',
                  'center': {'lat': 10.458, 'lon': 105.634},
                  'tags': {'name': 'Bến xe Cao Lãnh', 'amenity': 'bus_station'},
                },
                {
                  'type': 'node',
                  'lat': 10.459,
                  'lon': 105.635,
                  'tags': {'name': 'Nhà trọ C', 'building': 'dormitory'},
                },
                {
                  'type': 'node',
                  'lat': 10.46,
                  'lon': 105.636,
                  'tags': {
                    'name': 'Điểm dừng xe buýt A',
                    'highway': 'bus_stop',
                  },
                },
                {
                  'type': 'node',
                  'lat': 10.461,
                  'lon': 105.637,
                  'tags': {
                    'name': 'Trạm xe buýt B',
                    'public_transport': 'platform',
                    'bus': 'yes',
                  },
                },
              ],
            }),
          ),
          200,
        );
      }),
    );

    final places = await service.search(
      center: const LatLng(10.456, 105.632),
      radiusMeters: 5000,
    );

    expect(query, contains('guest_house'));
    expect(query, contains('dormitory'));
    expect(query, contains('bus_station'));
    expect(query, contains('highway'));
    expect(query, contains('stop_position'));
    expect(places.map((place) => place.category), [
      'tro',
      'tro',
      'ben_xe',
      'tro',
      'ben_xe',
      'ben_xe',
    ]);
  });

  test('chuyển sang dữ liệu offline khi dịch vụ không phản hồi', () async {
    SharedPreferences.setMockInitialValues({});
    final offlineElements = jsonEncode({
      'elements': [
        {
          'type': 'node',
          'lat': 10.4578,
          'lon': 105.6322,
          'tags': {
            'name': 'UBND Phuong Cao Lanh',
            'app:category': 'Co quan hanh chinh',
            'addr:full': 'So 03, duong 30/4',
          },
        },
      ],
    });
    final service = OverpassNearbyPlacesService(
      client: MockClient((request) async {
        if (request.method == 'GET') return http.Response(offlineElements, 200);
        return http.Response('busy', 503);
      }),
      useProxy: true,
    );

    await service.downloadOfflinePlaces();
    final places = await service.search(
      center: const LatLng(10.456, 105.632),
      radiusMeters: 1000,
    );

    expect(places, isNotEmpty);
    expect(places.any((place) => place.name == 'UBND Phuong Cao Lanh'), isTrue);
  });

  test('báo lỗi nếu proxy hỏng và chưa tải dữ liệu offline', () async {
    SharedPreferences.setMockInitialValues({});
    final service = OverpassNearbyPlacesService(
      client: MockClient((request) async {
        throw http.ClientException('Connection refused', request.url);
      }),
      useProxy: true,
    );

    await expectLater(
      service.search(center: const LatLng(10.456, 105.632), radiusMeters: 5000),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('localhost:8787'),
        ),
      ),
    );
  });

  test('đưa dữ liệu SQL đã tải offline vào đúng bộ lọc danh mục', () async {
    SharedPreferences.setMockInitialValues({});
    final service = OverpassNearbyPlacesService(
      useProxy: true,
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'elements': [
                {
                  'type': 'node',
                  'lat': 10.456,
                  'lon': 105.632,
                  'tags': {
                    'name': 'Van Mieu Cao Lanh & Cong vien Van Mieu',
                    'app:category': 'Cong vien - Van hoa',
                  },
                },
                {
                  'type': 'node',
                  'lat': 10.457,
                  'lon': 105.633,
                  'tags': {
                    'name': 'Cho Cao Lanh',
                    'app:category': 'Thuong mai',
                  },
                },
                {
                  'type': 'node',
                  'lat': 10.458,
                  'lon': 105.634,
                  'tags': {
                    'name': 'Dai hoc Dong Thap',
                    'app:category': 'Giao duc',
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response('offline', 503);
      }),
    );
    await service.downloadOfflinePlaces();

    final places = await service.search(
      center: const LatLng(10.456, 105.632),
      radiusMeters: 5000,
    );

    expect(
      places
          .firstWhere(
            (place) => place.name == 'Van Mieu Cao Lanh & Cong vien Van Mieu',
          )
          .category,
      'vui_choi',
    );
    expect(
      places.firstWhere((place) => place.name == 'Cho Cao Lanh').category,
      'mua_sam',
    );
    expect(
      places.firstWhere((place) => place.name == 'Dai hoc Dong Thap').category,
      'truong_hoc',
    );
  });
}
