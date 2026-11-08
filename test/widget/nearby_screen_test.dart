import 'dart:async';

import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/repositories/place_repository.dart';
import 'package:diadiem_quanh_day/features/admin/screens/admin_management_screen.dart';
import 'package:diadiem_quanh_day/features/gps/services/location_service.dart';
import 'package:diadiem_quanh_day/features/tim_kiem/screens/nearby_screen.dart';
import 'package:diadiem_quanh_day/features/tim_kiem/services/admin_error_log_service.dart';
import 'package:diadiem_quanh_day/features/tim_kiem/services/geocoding_service.dart';
import 'package:diadiem_quanh_day/features/tim_kiem/services/nearby_places_service.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/cao_lanh_ward_boundary.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/nearby_map.dart';
import 'package:diadiem_quanh_day/core/config/display_preferences.dart';
import 'package:diadiem_quanh_day/core/config/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePlaceService implements PlaceService {
  _FakePlaceService(this.places);

  final List<Place> places;

  @override
  Stream<List<Place>> watchAll() => Stream.value(places);

  @override
  Future<int> importAll(List<Place> places) async => places.length;
}

class _FakeAdminErrorLogService implements AdminErrorLogService {
  @override
  Future<void> record(AdminErrorCode code) async {}

  @override
  Stream<List<AdminErrorEntry>> watchRecent() => Stream.value(const []);
}

class _PendingPlaceService implements PlaceService {
  _PendingPlaceService(this.places);

  final Stream<List<Place>> places;

  @override
  Stream<List<Place>> watchAll() => places;

  @override
  Future<int> importAll(List<Place> places) async => places.length;
}

class _FakeGeocoder implements GeocodingService {
  @override
  Future<List<GeoResult>> search(String query) async => [
    GeoResult('Trường ĐH Đồng Tháp', const LatLng(10.4571, 105.6332)),
  ];
}

class _FakeNearbyPlacesService implements NearbyPlacesService {
  _FakeNearbyPlacesService(this.places);

  final List<Place> places;
  final List<({LatLng center, int radiusMeters})> searches = [];

  @override
  Future<List<Place>> search({
    required LatLng center,
    required int radiusMeters,
  }) async {
    searches.add((center: center, radiusMeters: radiusMeters));
    return places;
  }
}

class _FailingNearbyPlacesService implements NearbyPlacesService {
  @override
  Future<List<Place>> search({
    required LatLng center,
    required int radiusMeters,
  }) async {
    throw StateError('Backend địa điểm không khả dụng tại localhost:8787.');
  }
}

class _FakeLocationService implements LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;
  int calls = 0;

  @override
  Future<LocationResult> current() async {
    calls++;
    return result;
  }

  @override
  Future<void> openSettings() async {}
}

Place _place(String name, double lat, {double longitude = 105}) => Place.create(
  name: name,
  category: 'cafe',
  address: 'Địa chỉ $name',
  latitude: lat,
  longitude: longitude,
);

void main() {
  testWidgets('người không phải admin bị chặn khỏi trang quản lý', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminManagementScreen(
          isAdmin: false,
          placeService: _FakePlaceService(const []),
          draftService: _FakePlaceService(const []),
          adminErrorLogService: _FakeAdminErrorLogService(),
          locationService: _FakeLocationService(
            const LocationResult.failed(LocationFailure.serviceOff),
          ),
        ),
      ),
    );

    expect(
      find.text('Bạn không có quyền truy cập trang quản lý.'),
      findsOneWidget,
    );
    expect(find.text('Tạo bản nháp'), findsNothing);
  });

  testWidgets('admin có thể quay từ trang quản lý về chế độ người xem', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminManagementScreen(
                      isAdmin: true,
                      placeService: _FakePlaceService(const []),
                      draftService: _FakePlaceService(const []),
                      adminErrorLogService: _FakeAdminErrorLogService(),
                      locationService: _FakeLocationService(
                        const LocationResult.failed(LocationFailure.serviceOff),
                      ),
                    ),
                  ),
                ),
                child: const Text('Mở quản lý'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở quản lý'));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý hệ thống'), findsOneWidget);
    await tester.tap(find.text('Người xem'));
    await tester.pumpAndSettle();
    expect(find.text('Mở quản lý'), findsOneWidget);
  });

  testWidgets('renders the map while places are still loading', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final places = StreamController<List<Place>>();
    addTearDown(places.close);
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _PendingPlaceService(places.stream),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.failed(LocationFailure.serviceOff),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NearbyMap), findsOneWidget);
    expect(find.byKey(const ValueKey('nearby-list-background')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses sky-blue and pink-green lotus styling only in the list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            _place('Quán hoa sen', 10.46, longitude: 105.63),
          ]),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10.46, 105.63)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nearby-list-background')), findsNothing);

    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();

    final background = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('nearby-list-background')),
    );
    expect(background.color, const Color(0xFFE7F5FC));
    expect(find.byKey(const ValueKey('place-petal-badge')), findsOneWidget);
    expect(
      tester.widget<Card>(find.byType(Card).last).color,
      const Color(0xFFFFF1F6),
    );
  });

  testWidgets('cài đặt đồ họa và hiệu ứng được lưu trên thiết bị', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.failed(LocationFailure.serviceOff),
          ),
          isGuest: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt hiển thị'));
    await tester.pumpAndSettle();
    expect(find.text('Chất lượng đồ họa bản đồ'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(RadioListTile<MapGraphicsQuality>, 'Thấp'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hiệu ứng chuyển động'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('map_graphics_quality_v1'), 'low');
    expect(preferences.getBool('display_animations_enabled_v1'), isFalse);
  });

  testWidgets('admin có thể chọn và áp dụng snapshot bản đồ cũ', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    String? selectedSource;
    final nearbyService = OverpassNearbyPlacesService(
      useProxy: true,
      webBaseUrl: 'http://localhost:8787',
      getIdToken: () async => 'test-token',
      client: MockClient((request) async {
        if (request.url.path == '/api/admin/map-sources') {
          return http.Response(
            r'{"sources":['
            r'{"source":"current","label":"\u0110\u1ecba \u0111i\u1ec3m Cao L\u00e3nh m\u1edbi",'
            r'"file":"dia_diem_cao_lanh.json","count":20,"active":true},'
            r'{"source":"backup","label":"\u0110\u1ecba \u0111i\u1ec3m Cao L\u00e3nh c\u0169",'
            r'"file":"backup_dia_diem_cao_lanh.json","count":15,"active":false}'
            r']}',
            200,
          );
        }
        if (request.url.path == '/api/admin/select-map') {
          selectedSource = request.body;
          return http.Response(
            '{"source":"backup","file":"backup_dia_diem_cao_lanh.json",'
            '"count":15}',
            200,
          );
        }
        if (request.url.path == '/api/nearby') {
          return http.Response('{"elements":[]}', 200);
        }
        return http.Response('Not found', 404);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminManagementScreen(
          isAdmin: true,
          placeService: _FakePlaceService(const []),
          draftService: _FakePlaceService(const []),
          nearbyPlacesService: nearbyService,
          adminErrorLogService: _FakeAdminErrorLogService(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10.46, 105.63)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn snapshot đang sử dụng'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Địa điểm Cao Lãnh cũ'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(selectedSource, '{"source":"backup"}');
    expect(
      find.text('Đã dùng backup_dia_diem_cao_lanh.json: 15 địa điểm.'),
      findsOneWidget,
    );
  });

  testWidgets('hiển thị banner khám phá khi có danh sách địa điểm', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([_place('Quán xem thử', 10)]),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10, 105)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();
    expect(find.text('Tìm điểm đến quanh bạn'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/splash/launch.jpg',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Chơi mini game Cao Lãnh'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Thử thách Cao Lãnh'), findsOneWidget);
  });

  testWidgets('danh sách trống vẫn giữ banner và bộ lọc khám phá', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          isAdmin: true,
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10, 105)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();
    expect(find.text('Tìm điểm đến quanh bạn'), findsOneWidget);
    expect(
      find.textContaining('Không có địa điểm nào trong bán kính 5 km.'),
      findsOneWidget,
    );
    expect(find.text('Tạo bản nháp'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/splash/launch.jpg',
      ),
      findsOneWidget,
    );
    expect(find.text('Quán ăn'), findsNothing);
    expect(find.text('Bán kính:'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('toggle-nearby-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Quán ăn'), findsOneWidget);
    expect(find.text('Bán kính:'), findsOneWidget);
    expect(find.text('Tất cả'), findsNWidgets(2));
  });

  testWidgets('tài khoản thường không thấy mục vào trang quản lý', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10, 105)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Trang quản lý'), findsNothing);
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();
    expect(find.text('Tìm điểm đến quanh bạn'), findsOneWidget);
    expect(
      find.textContaining('Không có địa điểm nào trong bán kính 5 km.'),
      findsOneWidget,
    );
    expect(find.text('Tạo bản nháp'), findsNothing);
  });

  testWidgets('đưa công cụ sang trái và tài khoản về mép phải', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          favoriteService: null,
          userEmail: 'admin@example.com',
          isAdmin: true,
          onOpenAdminManagement: () {},
          onSignOut: () async {},
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10, 105)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gpsX = tester.getCenter(find.byTooltip('Dùng GPS')).dx;
    final accountX = tester.getCenter(find.byTooltip('Tài khoản')).dx;
    expect(accountX, greaterThan(gpsX));
    expect(find.byTooltip('Trang quản lý'), findsOneWidget);

    await tester.tap(find.byTooltip('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });

  testWidgets('khách xem bản đồ và lọc địa điểm nhưng cần đăng nhập vệ tinh', (
    tester,
  ) async {
    final requestedFeatures = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            _place('Quán xem thử', 10.4571, longitude: 105.6332),
          ]),
          isGuest: true,
          onRequireSignIn: requestedFeatures.add,
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10, 105)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('nearby-map-main')), findsOneWidget);
    expect(find.byTooltip('Xem danh sách'), findsNothing);
    expect(find.byTooltip('Dùng GPS'), findsNothing);
    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    final search = tester.widget<TextField>(find.byType(TextField).first);
    expect(search.readOnly, isFalse);
    await tester.tap(find.byKey(const ValueKey('toggle-nearby-filters')));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.byTooltip('Đăng nhập'), findsOneWidget);

    await tester.tap(find.byTooltip('Ẩn bộ tìm kiếm'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đăng nhập để xem ảnh vệ tinh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();
    expect(requestedFeatures, ['Xem ảnh vệ tinh']);
  });

  testWidgets('có thể xem ranh giới phường Cao Lãnh khi chưa nạp dữ liệu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.failed(LocationFailure.serviceOff),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('nearby-map-main')), findsOneWidget);
    expect(find.byType(PolygonLayer), findsOneWidget);
    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-nearby-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Phường Cao Lãnh, Đồng Tháp'), findsOneWidget);
    expect(find.text('1 km'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('10 km'), findsOneWidget);
    expect(find.byType(CircleLayer), findsOneWidget);
    final map = tester.widget<FlutterMap>(
      find.byKey(const ValueKey('nearby-map-main')),
    );
    expect(map.options.initialCenter.latitude, closeTo(10.4562617, 0.000001));
    expect(map.options.initialCenter.longitude, closeTo(105.6329173, 0.000001));
    expect(find.text('Xem vệ tinh'), findsOneWidget);

    await tester.tap(find.byTooltip('Chuyển sang ảnh vệ tinh'));
    await tester.pump();
    expect(
      tester
          .widget<TileLayer>(
            find.descendant(
              of: find.byKey(const ValueKey('nearby-map-main')),
              matching: find.byType(TileLayer),
            ),
          )
          .urlTemplate,
      AppLinks.satelliteTileUrl,
    );
    expect(find.text('Bản đồ thường'), findsOneWidget);
  });

  testWidgets('nút tìm kiếm nằm trong actions và có thể thu gọn thanh lọc', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.failed(LocationFailure.serviceOff),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hiện bộ tìm kiếm'), findsOneWidget);
    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('Phường Cao Lãnh, Đồng Tháp'), findsOneWidget);

    await tester.tap(find.byTooltip('Ẩn bộ tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('Phường Cao Lãnh, Đồng Tháp'), findsNothing);
    expect(find.byKey(const ValueKey('nearby-map-main')), findsOneWidget);
  });

  testWidgets('quản trị viên mặc định giản lược nước ngoài và có thể bật tắt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          isAdmin: true,
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.failed(LocationFailure.serviceOff),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('bản đồ mặc định lọc địa điểm theo bán kính 1, 5 và 10 km', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            _place('Trong 1 km', 10.4612, longitude: 105.6329),
            _place('Trong 5 km', 10.4962, longitude: 105.6329),
            _place('Trong 10 km', 10.5362, longitude: 105.6329),
          ]),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.failed(LocationFailure.serviceOff),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('nearby-map-main')), findsOneWidget);
    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-nearby-filters')));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(
      find.byKey(const ValueKey('nearby-map-main')),
    );
    expect(map.options.initialCenter.latitude, closeTo(10.4562617, 0.000001));
    MarkerLayer markerLayer() => tester.widget<MarkerLayer>(
      find.descendant(
        of: find.byKey(const ValueKey('nearby-map-main')),
        matching: find.byType(MarkerLayer),
      ),
    );
    CircleLayer circleLayer() =>
        tester.widget<CircleLayer>(find.byType(CircleLayer));
    expect(markerLayer().markers, hasLength(1));
    expect(circleLayer().circles.single.radius, 5000);

    await tester.tap(find.widgetWithText(ChoiceChip, '1 km'));
    await tester.pumpAndSettle();
    expect(markerLayer().markers, hasLength(1));
    expect(circleLayer().circles.single.radius, 1000);

    await tester.tap(find.widgetWithText(ChoiceChip, '10 km'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '10 km'))
          .selected,
      isTrue,
    );
    expect(markerLayer().markers, hasLength(1));
    expect(circleLayer().circles.single.radius, 10000);
  });

  testWidgets('bộ lọc nhận mã OSM cũ của bến xe và khách sạn', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            const Place(
              id: 'old-bus-stop',
              name: 'Điểm dừng cũ',
              category: 'bus_stop',
              address: 'Đường A',
              latitude: 10.46,
              longitude: 105.63,
            ),
            const Place(
              id: 'old-bus-station',
              name: 'Bến xe cũ',
              category: 'bus_station',
              address: 'Đường B',
              latitude: 10.461,
              longitude: 105.63,
            ),
            const Place(
              id: 'old-hotel',
              name: 'Khách sạn cũ',
              category: 'hotel',
              address: 'Đường C',
              latitude: 10.462,
              longitude: 105.63,
            ),
            const Place(
              id: 'nearby-cafe',
              name: 'Quán cà phê gần',
              category: 'cafe',
              address: 'Đường D',
              latitude: 10.463,
              longitude: 105.63,
            ),
            const Place(
              id: 'nearby-restaurant',
              name: 'Quán ăn gần',
              category: 'quan_an',
              address: 'Đường E',
              latitude: 10.464,
              longitude: 105.63,
            ),
            const Place(
              id: 'conflicting-library-category',
              name: 'Điểm dừng có nhãn lệch',
              category: 'khac',
              address: '',
              latitude: 10.461,
              longitude: 105.631,
            ),
          ]),
          nearbyPlacesService: _FakeNearbyPlacesService([
            const Place(
              id: 'conflicting-bus-category',
              name: 'Điểm dừng có nhãn lệch',
              category: 'bus_stop',
              address: '',
              latitude: 10.46105,
              longitude: 105.631,
            ),
          ]),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10.46, 105.63)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-nearby-filters')));
    await tester.pumpAndSettle();

    Future<void> scrollToResult(String name) async {
      final list = find.byKey(const ValueKey('nearby-places-list'));
      await tester.drag(list, const Offset(0, 1000));
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 5; attempt++) {
        if (find.text(name).evaluate().isNotEmpty) return;
        await tester.drag(list, const Offset(0, -180));
        await tester.pumpAndSettle();
      }
    }

    await tester.drag(
      find.byKey(const ValueKey('nearby-category-filters')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    final busFilter = find.widgetWithText(FilterChip, 'Bến xe / điểm dừng');
    await tester.tap(busFilter);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(busFilter).selected, isTrue);
    await scrollToResult('Điểm dừng cũ');
    expect(find.text('Điểm dừng cũ'), findsOneWidget);
    await scrollToResult('Bến xe cũ');
    expect(find.text('Bến xe cũ'), findsOneWidget);
    await scrollToResult('Điểm dừng có nhãn lệch');
    expect(find.text('Điểm dừng có nhãn lệch'), findsOneWidget);
    expect(find.text('Khách sạn cũ'), findsNothing);
    expect(find.text('Quán cà phê gần'), findsNothing);

    final lodgingFilter = find.widgetWithText(FilterChip, 'Nhà trọ');
    await tester.ensureVisible(lodgingFilter);
    await tester.tap(lodgingFilter);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(lodgingFilter).selected, isTrue);
    expect(tester.widget<FilterChip>(busFilter).selected, isTrue);
    await scrollToResult('Khách sạn cũ');
    expect(find.text('Khách sạn cũ'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('nearby-category-filters')),
      const Offset(600, 0),
    );
    await tester.pumpAndSettle();
    final cafeFilter = find.widgetWithText(FilterChip, 'Cà phê');
    await tester.tap(cafeFilter);
    await tester.pumpAndSettle();
    final foodFilter = find.widgetWithText(FilterChip, 'Quán ăn');
    await tester.tap(foodFilter);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(cafeFilter).selected, isTrue);
    expect(tester.widget<FilterChip>(foodFilter).selected, isTrue);
    await scrollToResult('Quán cà phê gần');
    expect(find.text('Quán cà phê gần'), findsOneWidget);
    await scrollToResult('Khách sạn cũ');
    expect(find.text('Khách sạn cũ'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('nearby-category-filters')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(busFilter);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(busFilter).selected, isFalse);
    expect(find.text('Điểm dừng cũ'), findsNothing);
    expect(find.text('Bến xe cũ'), findsNothing);
    await scrollToResult('Khách sạn cũ');
    expect(find.text('Khách sạn cũ'), findsOneWidget);
    await scrollToResult('Quán cà phê gần');
    expect(find.text('Quán cà phê gần'), findsOneWidget);
    await scrollToResult('Quán ăn gần');
    expect(find.text('Quán ăn gần'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('nearby-category-filters')),
      const Offset(600, 0),
    );
    await tester.pumpAndSettle();
    final allFilter = find.widgetWithText(FilterChip, 'Tất cả');
    await tester.tap(allFilter);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(allFilter).selected, isTrue);
    expect(tester.widget<FilterChip>(busFilter).selected, isFalse);
    expect(tester.widget<FilterChip>(lodgingFilter).selected, isFalse);
    expect(tester.widget<FilterChip>(cafeFilter).selected, isFalse);
    expect(tester.widget<FilterChip>(foodFilter).selected, isFalse);
    await scrollToResult('Điểm dừng cũ');
    expect(find.text('Điểm dừng cũ'), findsOneWidget);
  });

  testWidgets('tự tìm quán và trường theo bán kính, không cần GPS', (
    tester,
  ) async {
    final nearbyService = _FakeNearbyPlacesService([
      _place('Cà phê OSM', 10.4571, longitude: 105.6332),
      Place.create(
        name: 'Trường học OSM',
        category: 'truong_hoc',
        address: 'Đồng Tháp',
        latitude: 10.458,
        longitude: 105.634,
      ),
    ]);
    final locationService = _FakeLocationService(
      const LocationResult.failed(LocationFailure.serviceOff),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          nearbyPlacesService: nearbyService,
          geocoder: _FakeGeocoder(),
          locationService: locationService,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(locationService.calls, 0);
    expect(nearbyService.searches, hasLength(1));
    expect(nearbyService.searches.single.center, caoLanhWardCenter);
    expect(nearbyService.searches.single.radiusMeters, 5000);
    expect(find.byKey(const ValueKey('nearby-map-main')), findsOneWidget);
    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    final mainMapMarkers = find.descendant(
      of: find.byKey(const ValueKey('nearby-map-main')),
      matching: find.byType(MarkerLayer),
    );
    expect(mainMapMarkers, findsOneWidget);
    expect(tester.widget<MarkerLayer>(mainMapMarkers).markers, hasLength(1));
    expect(
      find.text('Giữ bản đồ để chọn tâm tìm kiếm, không cần bật GPS.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();
    expect(find.text('Cà phê OSM'), findsOneWidget);
    expect(find.text('Trường học OSM'), findsOneWidget);
    expect(
      find.text('Dữ liệu địa điểm © OpenStreetMap contributors'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('toggle-nearby-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '1 km'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(nearbyService.searches.last.radiusMeters, 1000);

    await tester.tap(find.byTooltip('Xem bản đồ'));
    await tester.pumpAndSettle();
    const selectedPoint = LatLng(10.47, 105.65);
    final map = tester.widget<FlutterMap>(
      find.byKey(const ValueKey('nearby-map-main')),
    );
    map.options.onLongPress!(
      const TapPosition(Offset.zero, null),
      selectedPoint,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(nearbyService.searches.last.center, selectedPoint);
    expect(find.text('Vị trí đã chọn trên bản đồ'), findsOneWidget);
    expect(locationService.calls, 0);
  });

  testWidgets('backend chưa chạy hiện hướng khởi động mà không che bản đồ', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          nearbyPlacesService: _FailingNearbyPlacesService(),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.failed(LocationFailure.serviceOff),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('nearby-map-main')), findsOneWidget);
    expect(find.textContaining('Backend địa điểm chưa chạy'), findsOneWidget);
    expect(find.textContaining('run_web.bat'), findsOneWidget);
    expect(find.textContaining('bat_app.bat'), findsOneWidget);
    expect(find.textContaining('Failed to fetch'), findsNothing);
    expect(find.textContaining('uri=overpass-api.de'), findsNothing);
    expect(find.textContaining('Chưa có địa điểm phù hợp'), findsNothing);

    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('Phường Cao Lãnh, Đồng Tháp'), findsOneWidget);
    await tester.tap(find.byTooltip('Ẩn bộ tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('Phường Cao Lãnh, Đồng Tháp'), findsNothing);
    expect(find.byKey(const ValueKey('nearby-map-main')), findsOneWidget);
  });

  testWidgets('sắp theo khoảng cách và bỏ điểm ngoài bán kính', (tester) async {
    final locationService = _FakeLocationService(
      const LocationResult.ok(LatLng(10.456, 105.63)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            _place('Xa', 10.476, longitude: 105.63), // ~2,2 km
            _place('Gần', 10.457, longitude: 105.63), // ~110 m
            _place(
              'Rất xa',
              10.4086,
              longitude: 105.63,
            ), // Ngoài bán kính 5 km, vẫn trong Cao Lãnh.
          ]),
          geocoder: _FakeGeocoder(),
          locationService: locationService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(locationService.calls, 0);
    await tester.tap(find.byTooltip('Dùng GPS'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();

    expect(find.text('Rất xa'), findsNothing);
    final near = tester.getTopLeft(find.text('Gần')).dy;
    final far = tester.getTopLeft(find.text('Xa')).dy;
    expect(near, lessThan(far));
  });

  testWidgets('chỉ hiển thị một bản ghi khi hai nguồn có cùng địa điểm', (
    tester,
  ) async {
    final savedPlace = _place('Cà phê trùng tên', 10.4571, longitude: 105.6332);
    final mapPlace = _place('Ca phe trung ten', 10.4572, longitude: 105.6332);
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([savedPlace]),
          nearbyPlacesService: _FakeNearbyPlacesService([mapPlace]),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10.4571, 105.6332)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();

    expect(find.text('Cà phê trùng tên'), findsOneWidget);
  });

  testWidgets('gợi ý tìm kiếm không lặp tên chi nhánh ở nhiều vị trí', (
    tester,
  ) async {
    const duplicatedName = 'Lần xe máy Cầu Cao Lãnh';
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          nearbyPlacesService: _FakeNearbyPlacesService([
            _place(duplicatedName, 10.461, longitude: 105.63),
            _place(duplicatedName, 10.462, longitude: 105.63),
          ]),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(LatLng(10.46, 105.63)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'máy');
    await tester.pumpAndSettle();

    expect(find.text(duplicatedName), findsOneWidget);
  });

  testWidgets('đánh dấu và căn bản đồ tới vị trí GPS hiện tại', (tester) async {
    const gpsPosition = LatLng(10.4571, 105.6332);
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService(const []),
          geocoder: _FakeGeocoder(),
          locationService: _FakeLocationService(
            const LocationResult.ok(gpsPosition),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dùng GPS'));
    await tester.pumpAndSettle();

    final map = find.byKey(const ValueKey('nearby-map-main'));
    final markerLayer = tester.widget<MarkerLayer>(
      find.descendant(of: map, matching: find.byType(MarkerLayer)).first,
    );
    final originMarker = markerLayer.markers.firstWhere(
      (marker) => marker.point == gpsPosition,
    );
    expect(originMarker.child, isA<Icon>());
    expect((originMarker.child as Icon).icon, Icons.location_pin);
  });

  testWidgets('không lấy được vị trí thì vẫn hiện tất cả và báo lý do', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      const LocationResult.failed(LocationFailure.denied),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            _place('Xa', 10.02),
            _place('Rất xa', 10.2),
          ]),
          geocoder: _FakeGeocoder(),
          locationService: locationService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(locationService.calls, 0);

    await tester.tap(find.byTooltip('Dùng GPS'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();

    expect(find.text('Xa'), findsOneWidget);
    expect(find.text('Rất xa'), findsOneWidget);
    expect(find.textContaining('Chưa được cấp quyền vị trí'), findsOneWidget);
    expect(find.textContaining('chọn địa điểm hoặc dùng GPS'), findsOneWidget);
  });

  testWidgets('không có GPS thì nhập địa chỉ để lấy vị trí xuất phát', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      const LocationResult.failed(LocationFailure.serviceOff),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            _place('Gần', 10.4575, longitude: 105.6332),
          ]),
          geocoder: _FakeGeocoder(),
          locationService: locationService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(locationService.calls, 0);
    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Phường Cao Lãnh'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'đại học');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trường ĐH Đồng Tháp'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();

    expect(find.text('Trường ĐH Đồng Tháp'), findsOneWidget); // thanh vị trí
    expect(
      find.textContaining(' m'),
      findsWidgets,
    ); // đã có khoảng cách (vd. 44 m)
    expect(locationService.calls, 0);
  });

  testWidgets('chọn địa điểm đã lưu mà không gọi GPS', (tester) async {
    final locationService = _FakeLocationService(
      const LocationResult.failed(LocationFailure.denied),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            _place('Quán quen', 10.4571, longitude: 105.6332),
          ]),
          geocoder: _FakeGeocoder(),
          locationService: locationService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(locationService.calls, 0);
    await tester.tap(find.byTooltip('Hiện bộ tìm kiếm'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Phường Cao Lãnh'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Quán quen');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quán quen').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();

    expect(find.text('Quán quen'), findsWidgets);
    expect(find.textContaining(' m'), findsWidgets);
    expect(locationService.calls, 0);
  });
}
