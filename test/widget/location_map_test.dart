import 'package:diadiem_quanh_day/core/config/display_preferences.dart';
import 'package:diadiem_quanh_day/core/config/app_links.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/cao_lanh_ward_boundary.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/location_map.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/map_zoom_controls.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/nearby_map.dart';
import 'package:diadiem_quanh_day/features/dia_diem/du_lieu/models/place.dart';
import 'package:diadiem_quanh_day/features/tim_kiem/widgets/place_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('điều khiển Zoom bị vô hiệu hóa trước khi map sẵn sàng', (
    tester,
  ) async {
    final controller = MapController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [MapZoomControls(controller: controller, enabled: false)],
          ),
        ),
      ),
    );

    final zoomIn = tester.widget<IconButton>(
      find
          .descendant(
            of: find.byType(MapZoomControls),
            matching: find.byType(IconButton),
          )
          .first,
    );
    expect(zoomIn.onPressed, isNull);
    await tester.tap(find.byTooltip('Phóng to bản đồ'));
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('Zoom hoạt động trong vùng camera bị khóa', (tester) async {
    final controller = MapController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: controller,
                options: MapOptions(
                  initialCenter: caoLanhWardCenter,
                  initialZoom: 12,
                  minZoom: 11,
                  maxZoom: 18,
                  cameraConstraint: CameraConstraint.containCenter(
                    bounds: caoLanhMapBounds,
                  ),
                ),
                children: const [],
              ),
              MapZoomControls(controller: controller, enabled: true),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Phóng to bản đồ'));
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, 13);
    await tester.tap(find.byTooltip('Thu nhỏ bản đồ'));
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, 12);
    controller.dispose();
  });

  test('đường dẫn chỉ đường chứa tọa độ đích', () {
    final uri = directionsUri(10.46, 105.63);
    expect(
      uri,
      Uri.parse(
        AppLinks.directionsUrl,
      ).replace(queryParameters: {'api': '1', 'destination': '10.46,105.63'}),
    );
    expect(uri.queryParameters['destination'], '10.46,105.63');
  });

  testWidgets('hiện bản đồ và nút Chỉ đường mở đúng link', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationMap(
            latitude: 10.46,
            longitude: 105.63,
            openUrl: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      ),
    );
    expect(find.byType(FlutterMap), findsOneWidget);
    await tester.tap(find.text('Chỉ đường'));
    expect(opened, directionsUri(10.46, 105.63));
  });

  testWidgets('đặt điều khiển Zoom ở góc trên bên trái', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LocationMap(latitude: 10.46, longitude: 105.63)),
      ),
    );

    final positioned = tester.widget<Positioned>(
      find
          .descendant(
            of: find.byType(MapZoomControls),
            matching: find.byType(Positioned),
          )
          .first,
    );
    expect(positioned.left, 12);
    expect(positioned.top, 12);
    expect(positioned.bottom, isNull);
  });

  testWidgets('hiển thị chú thích chủ quyền trên các bản đồ', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 300,
                child: NearbyMap(hits: [], origin: null, onSelect: _ignoreHit),
              ),
              LocationMap(latitude: 10.46, longitude: 105.63),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Hoàng Sa, Trường Sa là của Việt Nam'), findsNWidgets(2));
  });

  testWidgets('bản đồ tìm kiếm chỉ khóa tâm, không khóa Zoom', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NearbyMap(hits: [], origin: null, onSelect: _ignoreHit),
        ),
      ),
    );

    final map = tester.widget<FlutterMap>(
      find.byKey(const ValueKey('nearby-map-main')),
    );
    expect(map.options.cameraConstraint, isA<ContainCameraCenter>());
  });

  testWidgets('bản đồ tìm kiếm có inset Hoàng Sa, Trường Sa có thể ẩn/hiện', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NearbyMap(hits: [], origin: null, onSelect: _ignoreHit),
        ),
      ),
    );

    final insetMap = find.byKey(const ValueKey('vietnam-islands-inset-map'));
    expect(insetMap, findsOneWidget);
    final markers = find.descendant(
      of: insetMap,
      matching: find.byType(MarkerLayer),
    );
    expect(tester.widget<MarkerLayer>(markers).markers, hasLength(2));

    await tester.tap(find.byTooltip('Ẩn bản đồ Hoàng Sa, Trường Sa'));
    await tester.pumpAndSettle();
    expect(insetMap, findsNothing);
    await tester.tap(find.byTooltip('Hiện bản đồ Hoàng Sa, Trường Sa'));
    await tester.pumpAndSettle();
    expect(insetMap, findsOneWidget);
  });

  testWidgets('địa điểm được chọn chỉ hiển thị một marker', (tester) async {
    final place = Place.create(
      name: 'Quán cà phê',
      category: 'cafe',
      address: 'Cao Lãnh',
      latitude: 10.46,
      longitude: 105.63,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: NearbyMap(
              hits: [PlaceHit(place, 0)],
              origin: null,
              selectedPlaceId: place.id,
              onSelect: _ignoreHit,
              zoom: 18,
            ),
          ),
        ),
      ),
    );

    final mainMap = find.byKey(const ValueKey('nearby-map-main'));
    final markers = tester.widget<MarkerLayer>(
      find.descendant(of: mainMap, matching: find.byType(MarkerLayer)),
    );
    expect(markers.markers, hasLength(1));
  });

  testWidgets('bản đồ chỉ dựng marker địa điểm trong khung nhìn sau khi zoom', (
    tester,
  ) async {
    final visiblePlace = Place.create(
      name: 'Quán trong khung nhìn',
      category: 'cafe',
      address: 'Cao Lãnh',
      latitude: 10.46,
      longitude: 105.63,
    );
    final hits = [
      for (var index = 0; index < 300; index++)
        PlaceHit(
          Place.create(
            name: 'Quán ngoài khung nhìn $index',
            category: 'cafe',
            address: 'Cao Lãnh',
            latitude: 10.50,
            longitude: 105.63,
          ),
          4000,
        ),
      PlaceHit(visiblePlace, 0),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: NearbyMap(
              hits: hits,
              origin: visiblePlace.latLng,
              onSelect: _ignoreHit,
              zoom: 18,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    final mainMap = find.byKey(const ValueKey('nearby-map-main'));
    final markers = tester.widget<MarkerLayer>(
      find.descendant(of: mainMap, matching: find.byType(MarkerLayer)),
    );
    expect(markers.markers, hasLength(2));
    expect(
      markers.markers.where((marker) => marker.point == visiblePlace.latLng),
      hasLength(2),
    );
  });

  testWidgets('chất lượng thấp giảm đệm tile và tắt fade khi animation tắt', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: NearbyMap(
              hits: [],
              origin: null,
              onSelect: _ignoreHit,
              graphicsQuality: MapGraphicsQuality.low,
              animationsEnabled: false,
            ),
          ),
        ),
      ),
    );

    final tileLayer = tester.widget<TileLayer>(
      find.descendant(
        of: find.byKey(const ValueKey('nearby-map-main')),
        matching: find.byType(TileLayer),
      ),
    );
    expect(tileLayer.panBuffer, 0);
    expect(tileLayer.keepBuffer, 0);
    expect(tileLayer.tileDisplay, isA<InstantaneousTileDisplay>());
  });

  testWidgets('chuyển được giữa bản đồ đường phố và ảnh vệ tinh', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LocationMap(latitude: 10.46, longitude: 105.63)),
      ),
    );

    TileLayer tileLayer() => tester.widget<TileLayer>(find.byType(TileLayer));
    expect(tileLayer().urlTemplate, AppLinks.streetTileUrl);
    expect(find.text('Xem vệ tinh'), findsOneWidget);

    await tester.tap(find.byTooltip('Chuyển sang ảnh vệ tinh'));
    await tester.pump();
    expect(tileLayer().urlTemplate, AppLinks.satelliteTileUrl);
    expect(find.text('Bản đồ thường'), findsOneWidget);
    expect(
      find.textContaining('Esri, Maxar, Earthstar Geographics'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Chuyển sang bản đồ đường phố'));
    await tester.pump();
    expect(tileLayer().urlTemplate, AppLinks.streetTileUrl);
    expect(find.text('Xem vệ tinh'), findsOneWidget);
  });
}

void _ignoreHit(Object hit) {}
