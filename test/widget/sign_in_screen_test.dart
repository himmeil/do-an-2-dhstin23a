import 'package:diadiem_quanh_day/features/tai_khoan/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows location artwork and guest option on sign-in screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(
          onSubmit: ({
            required email,
            required password,
            required register,
          }) async {},
          onContinueAsGuest: () {},
          promptMessage: 'Đăng nhập để lưu địa điểm yêu thích.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khám phá Cao Lãnh'), findsOneWidget);
    expect(find.text('Đăng nhập để lưu địa điểm yêu thích.'), findsOneWidget);
    expect(find.text('Tiếp tục xem với tư cách khách'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
          return false;
        }
        final gradient = (widget.decoration as BoxDecoration).gradient;
        return gradient is LinearGradient &&
            gradient.colors.length == 3 &&
            gradient.colors[0] == const Color(0xFFE1F1FA) &&
            gradient.colors[1] == const Color(0xFFFFEDF3);
      }),
      findsOneWidget,
    );
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps register and guest actions available', (tester) async {
    var continuedAsGuest = false;
    Map<String, Object?>? submitted;

    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(
          onSubmit:
              ({required email, required password, required register}) async {
                submitted = {
                  'email': email,
                  'password': password,
                  'register': register,
                };
              },
          onContinueAsGuest: () => continuedAsGuest = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(submitted, {
      'email': 'user@example.com',
      'password': 'password123',
      'register': true,
    });

    await tester.ensureVisible(find.text('Tiếp tục xem với tư cách khách'));
    await tester.tap(find.text('Tiếp tục xem với tư cách khách'));
    expect(continuedAsGuest, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pressing Enter advances fields and submits sign-in', (
    tester,
  ) async {
    Map<String, Object?>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(
          onSubmit:
              ({required email, required password, required register}) async {
                submitted = {
                  'email': email,
                  'password': password,
                  'register': register,
                };
              },
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submitted, {
      'email': 'user@example.com',
      'password': 'password123',
      'register': false,
    });
    expect(tester.takeException(), isNull);
  });
}
