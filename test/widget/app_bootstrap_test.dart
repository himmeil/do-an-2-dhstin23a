import 'dart:async';

import 'package:diadiem_quanh_day/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a sky-blue loading screen while Firebase initializes', (
    tester,
  ) async {
    final initialization = Completer<FirebaseApp>();
    await tester.pumpWidget(
      NearbyApp(initializeFirebase: () => initialization.future),
    );

    expect(find.text('Đang khởi tạo ứng dụng...'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFFE7F5FC));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a retry action when Firebase initialization fails', (
    tester,
  ) async {
    var attempts = 0;
    final retryInitialization = Completer<FirebaseApp>();
    await tester.pumpWidget(
      NearbyApp(
        initializeFirebase: () {
          attempts++;
          return attempts == 1
              ? Future<FirebaseApp>.error(
                  FirebaseException(
                    plugin: 'firebase_core',
                    code: 'configuration-not-found',
                  ),
                )
              : retryInitialization.future;
        },
      ),
    );
    await tester.pump();

    expect(find.text('Mã lỗi: FIREBASE_INIT_FAILED'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('Đang khởi tạo ứng dụng...'), findsOneWidget);
  });
}
