import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationFailure { serviceOff, denied, deniedForever, error }

class LocationResult {
  const LocationResult.ok(LatLng this.position) : failure = null;
  const LocationResult.failed(LocationFailure this.failure) : position = null;

  final LatLng? position;
  final LocationFailure? failure;
}

abstract interface class LocationService {
  /// Lấy vị trí hiện tại; xin quyền nếu chưa có.
  Future<LocationResult> current();

  /// Mở cài đặt của app (khi người dùng đã chặn quyền vĩnh viễn).
  Future<void> openSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failed(LocationFailure.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failed(LocationFailure.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failed(LocationFailure.deniedForever);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult.ok(LatLng(position.latitude, position.longitude));
    } catch (_) {
      return const LocationResult.failed(LocationFailure.error);
    }
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
