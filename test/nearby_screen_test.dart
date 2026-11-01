import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/services/place_service.dart';
import 'package:diadiem_quanh_day/features/dia_diem/gps/services/location_service.dart';
import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/screens/nearby_screen.dart';
import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/services/geocoding_service.dart';
import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/services/nearby_places_service.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/cao_lanh_ward_boundary.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/foreign_countries_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
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
    throw Exception('ClientException: Failed to fetch, uri=overpass-api.de');
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
          draftService: _FakePlaceService(const []),
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

    await tester.tap(find.byTooltip('Công cụ quản trị'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo bản nháp'), findsOneWidget);
  });

  testWidgets('tài khoản thường không có nút tạo bản nháp', (tester) async {
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
          draftService: _FakePlaceService(const []),
          favoriteService: null,
          userEmail: 'admin@example.com',
          isAdmin: true,
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
    expect(find.byTooltip('Công cụ quản trị'), findsOneWidget);

    await tester.tap(find.byTooltip('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });

  testWidgets('khách xem được danh sách nhưng đăng nhập mới được tìm/vệ tinh', (
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
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();
    expect(find.text('Quán xem thử'), findsOneWidget);
    final search = tester.widget<TextField>(find.byType(TextField).first);
    expect(search.readOnly, isTrue);
    expect(find.byTooltip('Đăng nhập'), findsOneWidget);

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();
    expect(requestedFeatures, ['Tìm kiếm địa điểm']);

    await tester.tap(find.byTooltip('Xem bản đồ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đăng nhập để xem ảnh vệ tinh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();
    expect(requestedFeatures, ['Tìm kiếm địa điểm', 'Xem ảnh vệ tinh']);
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
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
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

    expect(find.byType(ForeignCountriesLayer), findsOneWidget);

    await tester.tap(find.byTooltip('Công cụ quản trị'));
    await tester.pumpAndSettle();
    expect(find.text('Tắt đơn giản hóa nước ngoài'), findsOneWidget);
    await tester.tap(find.text('Tắt đơn giản hóa nước ngoài'));
    await tester.pumpAndSettle();
    expect(find.byType(ForeignCountriesLayer), findsNothing);

    await tester.tap(find.byTooltip('Công cụ quản trị'));
    await tester.pumpAndSettle();
    expect(find.text('Bật đơn giản hóa nước ngoài'), findsOneWidget);
    await tester.tap(find.text('Bật đơn giản hóa nước ngoài'));
    await tester.pumpAndSettle();
    expect(find.byType(ForeignCountriesLayer), findsOneWidget);
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
    expect(markerLayer().markers, hasLength(3));
    expect(circleLayer().circles.single.radius, 5000);

    await tester.tap(find.widgetWithText(ChoiceChip, '1 km'));
    await tester.pumpAndSettle();
    expect(markerLayer().markers, hasLength(2));
    expect(circleLayer().circles.single.radius, 1000);

    await tester.tap(find.widgetWithText(ChoiceChip, '10 km'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '10 km'))
          .selected,
      isTrue,
    );
    expect(markerLayer().markers, hasLength(4));
    expect(circleLayer().circles.single.radius, 10000);
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
    expect(tester.widget<MarkerLayer>(mainMapMarkers).markers, hasLength(3));
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

  testWidgets('lỗi Overpass không phủ bản đồ hoặc lộ exception kỹ thuật', (
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
    expect(
      find.textContaining('Không kết nối được dữ liệu địa điểm OpenStreetMap'),
      findsOneWidget,
    );
    expect(find.textContaining('CORS'), findsOneWidget);
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
      const LocationResult.ok(LatLng(10, 105)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NearbyScreen(
          service: _FakePlaceService([
            _place('Xa', 10.02), // ~2,2 km
            _place('Gần', 10.001), // ~110 m
            _place('Rất xa', 10.2), // ~22 km, ngoài bán kính 5 km
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
