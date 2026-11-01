import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/services/place_service.dart';
import 'package:diadiem_quanh_day/features/dia_diem/gps/services/location_service.dart';
import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/screens/nearby_screen.dart';
import 'package:diadiem_quanh_day/features/dia_diem/tim_kiem/services/geocoding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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
  testWidgets('chưa có dữ liệu thì mời nạp dữ liệu lần đầu', (tester) async {
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
    expect(find.textContaining('Chưa có địa điểm nào'), findsOneWidget);
    expect(find.text('Nạp dữ liệu'), findsOneWidget);
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
    await tester.tap(find.text('Xem phường Cao Lãnh trên bản đồ'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolygonLayer), findsOneWidget);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter.latitude, closeTo(10.4562617, 0.000001));
    expect(map.options.initialCenter.longitude, closeTo(105.6329173, 0.000001));
    expect(find.text('Xem vệ tinh'), findsOneWidget);

    await tester.tap(find.byTooltip('Chuyển sang ảnh vệ tinh'));
    await tester.pump();
    expect(
      tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    );
    expect(find.text('Bản đồ thường'), findsOneWidget);
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
    await tester.tap(find.textContaining('Chưa chọn vị trí'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'đại học');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trường ĐH Đồng Tháp'));
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
    await tester.tap(find.textContaining('Chưa chọn vị trí'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Quán quen');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quán quen').last);
    await tester.pumpAndSettle();

    expect(find.text('Quán quen'), findsWidgets);
    expect(find.textContaining(' m'), findsWidgets);
    expect(locationService.calls, 0);
  });
}
