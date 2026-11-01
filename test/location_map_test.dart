import 'package:diadiem_quanh_day/features/dia_diem/ban_do/widgets/location_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
