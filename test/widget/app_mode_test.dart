import 'package:diadiem_quanh_day/features/tim_kiem/screens/nearby_screen.dart';
import 'package:diadiem_quanh_day/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('local mode opens without initializing Firebase', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var firebaseInitializationCalled = false;

    await tester.pumpWidget(
      NearbyApp(
        isLocalMode: true,
        initializeFirebase: () async {
          firebaseInitializationCalled = true;
          throw StateError('Local mode must not initialize Firebase.');
        },
      ),
    );
    await tester.pump();

    expect(firebaseInitializationCalled, isFalse);
    expect(find.byType(NearbyScreen), findsOneWidget);
  });
}
