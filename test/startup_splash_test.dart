import 'package:diadiem_quanh_day/core/widgets/splash/startup_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the launch photo before revealing the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StartupSplash(child: Scaffold(body: Text('Nội dung ứng dụng'))),
      ),
    );

    expect(find.byKey(const ValueKey('startup-splash')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Nội dung ứng dụng'), findsOneWidget);
    expect(find.text('ĐANG KHỞI TẠO'), findsOneWidget);
    expect(find.text('0%'), findsNothing);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('HOÀN THÀNH'), findsOneWidget);
    expect(find.text('ĐANG KHỞI TẠO'), findsNothing);
    final percentFinder = find.byKey(const ValueKey('startup-splash-percent'));
    expect(percentFinder, findsOneWidget);
    final firstPercent = int.parse(
      tester.widget<Text>(percentFinder).data!.replaceAll('%', ''),
    );

    await tester.pump(const Duration(milliseconds: 500));
    final nextPercent = int.parse(
      tester.widget<Text>(percentFinder).data!.replaceAll('%', ''),
    );
    expect(nextPercent, greaterThan(firstPercent));
    expect(nextPercent, 100);
    expect(find.text('ĐANG VÀO APP'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('startup-splash')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(const ValueKey('startup-splash')), findsNothing);
    expect(find.text('Nội dung ứng dụng'), findsOneWidget);
  });
}
