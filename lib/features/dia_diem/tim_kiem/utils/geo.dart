import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../../core/utils/text_utils.dart';
import '../../du_lieu/models/place.dart';
import '../../du_lieu/models/place_category_registry.dart';

/// Khoảng cách đường chim bay giữa 2 điểm (mét), công thức Haversine.
double distanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h)));
}

/// Loại các bản ghi cùng tên và cùng địa chỉ hoặc nằm cách nhau không quá 50 m.
/// Giữ bản ghi xuất hiện trước để ưu tiên dữ liệu địa phương khi gộp nguồn.
List<Place> deduplicatePlaces(
  Iterable<Place> places, {
  bool preserveDifferentCategories = false,
}) {
  const duplicateDistanceMeters = 50.0;
  final unique = <Place>[];
  final placesByName = <String, List<Place>>{};

  for (final place in places) {
    final name = _normalizedPlaceText(place.name);
    if (name.isEmpty) {
      unique.add(place);
      continue;
    }

    final address = _normalizedPlaceText(place.address);
    final namedPlaces = placesByName.putIfAbsent(name, () => []);
    final isDuplicate = namedPlaces.any((existing) {
      if (preserveDifferentCategories &&
          parseCategoryCode(existing.category) !=
              parseCategoryCode(place.category)) {
        return false;
      }
      final existingAddress = _normalizedPlaceText(existing.address);
      final sameAddress =
          address.isNotEmpty &&
          address != _unknownAddress &&
          address == existingAddress &&
          existingAddress != _unknownAddress;
      return sameAddress ||
          distanceMeters(existing.latLng, place.latLng) <=
              duplicateDistanceMeters;
    });
    if (!isDuplicate) {
      namedPlaces.add(place);
      unique.add(place);
    }
  }
  return unique;
}

const _unknownAddress = 'chua co dia chi';

String _normalizedPlaceText(String value) =>
    foldVietnamese(value).trim().replaceAll(RegExp(r'\s+'), ' ');

/// "450 m", "1,5 km", "12 km".
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}
