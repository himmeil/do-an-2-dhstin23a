import 'package:diadiem_quanh_day/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes loopback hosts as local development', () {
    expect(AppEnvironment.isLocalHost('localhost'), isTrue);
    expect(AppEnvironment.isLocalHost('127.0.0.1'), isTrue);
    expect(AppEnvironment.isLocalHost('::1'), isTrue);
    expect(AppEnvironment.isLocalHost('app.localhost'), isTrue);
    expect(AppEnvironment.isLocalHost('192.168.1.25'), isTrue);
    expect(AppEnvironment.isLocalHost('10.0.0.12'), isTrue);
  });

  test('recognizes non-loopback hosts as hosted deployments', () {
    expect(AppEnvironment.isFirebaseHost('do-an-2-b1f35.web.app'), isTrue);
    expect(AppEnvironment.isFirebaseHost('example.com'), isTrue);
    expect(AppEnvironment.isFirebaseHost('localhost'), isFalse);
  });
}
