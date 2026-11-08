import 'package:flutter/foundation.dart' show kIsWeb;

enum AppDeploymentMode { automatic, local, firebase }

abstract final class AppEnvironment {
  static const _modeName = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'auto',
  );
  static AppDeploymentMode get mode => switch (_modeName) {
    'local' => AppDeploymentMode.local,
    'firebase' => AppDeploymentMode.firebase,
    _ => AppDeploymentMode.automatic,
  };

  static bool get isFirebaseHosted {
    if (mode == AppDeploymentMode.firebase) return true;
    if (mode == AppDeploymentMode.local || !kIsWeb) return false;
    return isFirebaseHost(Uri.base.host);
  }

  static bool get isLocalMode => mode == AppDeploymentMode.local || isLocalWeb;

  static bool get isLocalWeb =>
      kIsWeb &&
      (mode == AppDeploymentMode.local ||
          (mode == AppDeploymentMode.automatic && isLocalHost(Uri.base.host)));

  static bool isLocalHost(String host) {
    final normalizedHost = host.toLowerCase();
    if (normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '::1' ||
        normalizedHost == '0.0.0.0' ||
        normalizedHost.endsWith('.localhost')) {
      return true;
    }

    final octets = normalizedHost.split('.');
    if (octets.length != 4) return false;
    final address = octets.map(int.tryParse).toList();
    if (address.any((octet) => octet == null || octet < 0 || octet > 255)) {
      return false;
    }

    final first = address[0]!;
    final second = address[1]!;
    return first == 10 ||
        first == 127 ||
        (first == 192 && second == 168) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 169 && second == 254);
  }

  static bool isFirebaseHost(String host) => !isLocalHost(host);
}
