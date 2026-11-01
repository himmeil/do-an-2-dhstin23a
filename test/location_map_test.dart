import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/location_map.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/nearby_map.dart';
import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/foreign_countries_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('đường dẫn chỉ đường chứa tọa độ đích', () {
    final uri = directionsUri(10.46, 105.63);
    expect(uri.host, 'www.google.com');
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

  testWidgets('lớp giản lược che chi tiết nước ngoài và ghi tên quốc gia', (
    tester,
  ) async {
    final mapData = await tester.runAsync(
      () => rootBundle.loadString('assets/maps/countries_110m.geojson'),
    );
    expect(mapData, isNotEmpty);
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 900,
          height: 600,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(10.46, 105.63),
              initialZoom: 3,
            ),
            children: [ForeignCountriesLayer()],
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được ranh giới quốc gia.'), findsNothing);
    final layer = find.byType(ForeignCountriesLayer);
    final polygons = find.descendant(
      of: layer,
      matching: find.byType(PolygonLayer),
    );
    expect(
      tester.widget<PolygonLayer>(polygons).polygons.length,
      greaterThan(150),
    );
    final simplifiedPolygons = tester.widget<PolygonLayer>(polygons).polygons;
    expect(
      simplifiedPolygons.any((polygon) => polygon.label == 'Campuchia'),
      isTrue,
    );
    expect(
      simplifiedPolygons.any((polygon) => polygon.label == 'Trung Quốc'),
      isTrue,
    );
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
    expect(
      tileLayer().urlTemplate,
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    expect(find.text('Xem vệ tinh'), findsOneWidget);

    await tester.tap(find.byTooltip('Chuyển sang ảnh vệ tinh'));
    await tester.pump();
    expect(
      tileLayer().urlTemplate,
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    );
    expect(find.text('Bản đồ thường'), findsOneWidget);
    expect(
      find.textContaining('Esri, Maxar, Earthstar Geographics'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Chuyển sang bản đồ đường phố'));
    await tester.pump();
    expect(
      tileLayer().urlTemplate,
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    expect(find.text('Xem vệ tinh'), findsOneWidget);
  });

  testWidgets('giản lược nước ngoài vẫn bật trên ảnh vệ tinh', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NearbyMap(
            hits: [],
            origin: null,
            onSelect: _ignoreHit,
            simplifyForeignCountries: true,
          ),
        ),
      ),
    );

    expect(find.byType(ForeignCountriesLayer), findsOneWidget);
    await tester.tap(find.byTooltip('Chuyển sang ảnh vệ tinh'));
    await tester.pump();

    expect(find.byType(ForeignCountriesLayer), findsOneWidget);
  });
}

void _ignoreHit(Object hit) {}
