import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../du_lieu/models/place.dart';
import '../utils/geo.dart';

abstract interface class NearbyPlacesService {
  Future<List<Place>> search({
    required LatLng center,
    required int radiusMeters,
  });
}

/// Finds named cafes and schools from OpenStreetMap without saving them locally.
class OverpassNearbyPlacesService implements NearbyPlacesService {
  OverpassNearbyPlacesService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<Place>> search({
    required LatLng center,
    required int radiusMeters,
  }) async {
    if (radiusMeters <= 0) {
      throw ArgumentError.value(
        radiusMeters,
        'radiusMeters',
        'Must be positive',
      );
    }

    final query =
        '[out:json][timeout:20];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["amenity"~"^(cafe|school|college|university)\$"];'
        'out center tags;';
    final response = await _client
        .post(
          Uri.https('overpass-api.de', '/api/interpreter'),
          headers: {
            if (!kIsWeb) 'User-Agent': 'vn.diadiem.quanhday',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception(
        'Không tìm được địa điểm quanh đây (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['elements'] is! List) {
      throw const FormatException(
        'Dữ liệu địa điểm từ OpenStreetMap không hợp lệ.',
      );
    }

    final places = <Place>[];
    for (final element in decoded['elements'] as List) {
      if (element is! Map || element['tags'] is! Map) continue;
      final tags = Map<String, dynamic>.from(element['tags'] as Map);
      final name = '${tags['name'] ?? tags['name:vi'] ?? ''}'.trim();
      if (name.isEmpty) continue;

      final lat = _coordinate(
        element['lat'] ?? (element['center'] as Map?)?['lat'],
      );
      final lon = _coordinate(
        element['lon'] ?? (element['center'] as Map?)?['lon'],
      );
      if (lat == null || lon == null) continue;

      final amenity = '${tags['amenity'] ?? ''}';
      final isSchool = const {
        'school',
        'college',
        'university',
      }.contains(amenity);
      places.add(
        Place.create(
          name: name,
          category: isSchool ? 'truong_hoc' : 'cafe',
          address: _address(tags),
          latitude: lat,
          longitude: lon,
          phone: '${tags['contact:phone'] ?? tags['phone'] ?? ''}',
          hours: '${tags['opening_hours'] ?? ''}',
        ),
      );
    }

    final unique = {for (final place in places) place.id: place}.values.toList()
      ..sort(
        (a, b) => distanceMeters(
          center,
          a.latLng,
        ).compareTo(distanceMeters(center, b.latLng)),
      );
    return unique;
  }

  double? _coordinate(Object? raw) =>
      raw is num ? raw.toDouble() : double.tryParse('$raw');

  String _address(Map<String, dynamic> tags) {
    final full = '${tags['addr:full'] ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    final street = '${tags['addr:street'] ?? ''}'.trim();
    final houseNumber = '${tags['addr:housenumber'] ?? ''}'.trim();
    final city = '${tags['addr:city'] ?? ''}'.trim();
    final parts = [
      if (houseNumber.isNotEmpty) houseNumber,
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
    ];
    return parts.isEmpty ? 'Chưa có địa chỉ' : parts.join(', ');
  }
}
