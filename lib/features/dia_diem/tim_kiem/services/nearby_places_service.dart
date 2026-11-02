import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/text_utils.dart';
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
  OverpassNearbyPlacesService({
    http.Client? client,
    String? webBaseUrl,
    bool? useProxy,
  }) : _client = client ?? http.Client(),
       _webBaseUrl =
           webBaseUrl ??
           const String.fromEnvironment(
             'NEARBY_API_BASE_URL',
             defaultValue: 'http://localhost:8787',
           ),
       _useProxy = useProxy ?? kIsWeb;

  final http.Client _client;
  final String _webBaseUrl;
  final bool _useProxy;
  static const offlineCacheKey = 'nearby_places_sql_download_v1';

  Future<int> downloadOfflinePlaces() async {
    if (!_useProxy) {
      throw StateError('Tải dữ liệu offline cần chạy qua server Web local.');
    }

    final response = await _client
        .get(
          Uri.parse(
            '${_webBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/offline-places',
          ),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'Không tải được dữ liệu offline (${response.statusCode}).',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['elements'] is! List) {
      throw const FormatException('Dữ liệu offline không hợp lệ.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      offlineCacheKey,
      jsonEncode(decoded['elements']),
    );
    return (decoded['elements'] as List).length;
  }

  Future<int> updateMapFromOverpass() async {
    if (!_useProxy) {
      throw StateError('Cập nhật bản đồ cần chạy qua server Web local.');
    }
    final response = await _client
        .post(
          Uri.parse(
            '${_webBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/admin/update-map',
          ),
        )
        .timeout(const Duration(minutes: 10));
    if (response.statusCode != 200) {
      throw Exception('Không cập nhật được bản đồ (${response.statusCode}).');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['count'] is! num) {
      throw const FormatException('Phản hồi cập nhật bản đồ không hợp lệ.');
    }
    return (decoded['count'] as num).toInt();
  }

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
        '('
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["amenity"~"^(cafe|restaurant|fast_food|bar|pub|cinema|school|college|university)\$"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["leisure"~"^(park|playground|amusement_arcade|water_park|sports_centre|stadium)\$"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["shop"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["tourism"~"^(theme_park|zoo|museum|attraction)\$"];'
        ');out center tags;';
    final uri = _useProxy
        ? Uri.parse('${_webBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/nearby')
        : Uri.https('overpass-api.de', '/api/interpreter');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              if (!_useProxy) 'User-Agent': 'vn.diadiem.quanhday',
              'Content-Type': _useProxy
                  ? 'application/json'
                  : 'application/x-www-form-urlencoded',
            },
            body: _useProxy
                ? jsonEncode({
                    'latitude': center.latitude,
                    'longitude': center.longitude,
                    'radiusMeters': radiusMeters,
                  })
                : {'data': query},
          )
          .timeout(Duration(seconds: _useProxy ? 5 : 25));
      if (response.statusCode != 200) {
        return await _offlineSearch(center, radiusMeters);
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['elements'] is! List) {
        return await _offlineSearch(center, radiusMeters);
      }
      return _placesFromElements(decoded['elements'] as List, center);
    } catch (_) {
      return await _offlineSearch(center, radiusMeters);
    }
  }

  List<Place> _placesFromElements(List elements, LatLng center) {
    final places = <Place>[];
    for (final element in elements) {
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

      final category = _categoryForTags(tags);
      places.add(
        Place.create(
          name: name,
          category: category,
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

  Future<List<Place>> _offlineSearch(LatLng center, int radiusMeters) async {
    final preferences = await SharedPreferences.getInstance();
    final cached = preferences.getString(offlineCacheKey);
    if (cached == null) return const [];
    final decoded = jsonDecode(cached);
    if (decoded is! List) return const [];
    final places = <Place>[];
    for (final element in decoded) {
      if (element is! Map || element['tags'] is! Map) continue;
      final tags = Map<String, dynamic>.from(element['tags'] as Map);
      final latitude = _coordinate(
        element['lat'] ?? (element['center'] as Map?)?['lat'],
      );
      final longitude = _coordinate(
        element['lon'] ?? (element['center'] as Map?)?['lon'],
      );
      if (latitude == null || longitude == null) continue;
      final place = Place.create(
        name: '${tags['name'] ?? tags['name:vi'] ?? ''}',
        category: _categoryForTags(tags),
        address: _address(tags),
        latitude: latitude,
        longitude: longitude,
        phone: '${tags['phone'] ?? ''}',
        hours: '${tags['opening_hours'] ?? ''}',
      );
      if (distanceMeters(center, place.latLng) <= radiusMeters) {
        places.add(place);
      }
    }
    places.sort(
      (a, b) => distanceMeters(
        center,
        a.latLng,
      ).compareTo(distanceMeters(center, b.latLng)),
    );
    return places;
  }

  double? _coordinate(Object? raw) =>
      raw is num ? raw.toDouble() : double.tryParse('$raw');

  String _categoryForTags(Map<String, dynamic> tags) {
    final localCategory = foldVietnamese('${tags['app:category'] ?? ''}')
        .toLowerCase();
    if (localCategory.contains('cong vien') ||
        localCategory.contains('du lich') ||
        localCategory.contains('di tich') ||
        localCategory.contains('van hoa') ||
        localCategory.contains('bao tang')) {
      return 'vui_choi';
    }
    if (localCategory.contains('thuong mai')) return 'mua_sam';
    if (localCategory.contains('giao duc') ||
        localCategory.contains('truong hoc')) {
      return 'truong_hoc';
    }

    final amenity = '${tags['amenity'] ?? ''}';
    if (const {'school', 'college', 'university'}.contains(amenity)) {
      return 'truong_hoc';
    }
    if (const {'cafe'}.contains(amenity)) return 'cafe';
    if (const {'restaurant', 'fast_food'}.contains(amenity)) return 'quan_an';
    if (const {'bar', 'pub'}.contains(amenity)) return 'vui_choi';
    if (amenity == 'cinema') return 'vui_choi';

    final leisure = '${tags['leisure'] ?? ''}';
    if (const {
      'park',
      'playground',
      'amusement_arcade',
      'water_park',
      'sports_centre',
      'stadium',
    }.contains(leisure)) {
      return 'vui_choi';
    }

    final tourism = '${tags['tourism'] ?? ''}';
    if (const {'theme_park', 'zoo', 'museum', 'attraction'}.contains(tourism)) {
      return 'vui_choi';
    }

    if ('${tags['shop'] ?? ''}'.isNotEmpty) return 'mua_sam';
    return 'khac';
  }

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
