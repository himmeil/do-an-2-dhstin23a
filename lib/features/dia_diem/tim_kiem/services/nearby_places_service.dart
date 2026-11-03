import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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

class MapDataSource {
  const MapDataSource({
    required this.source,
    required this.label,
    required this.file,
    required this.count,
    required this.active,
    this.updatedAt,
  });

  final String source;
  final String label;
  final String file;
  final int count;
  final bool active;
  final DateTime? updatedAt;

  factory MapDataSource.fromMap(Map<dynamic, dynamic> map) {
    final source = map['source'];
    final label = map['label'];
    final file = map['file'];
    final count = map['count'];
    final active = map['active'];
    if (source is! String ||
        label is! String ||
        file is! String ||
        count is! num ||
        active is! bool) {
      throw const FormatException(
        'Thông tin nguồn dữ liệu bản đồ không hợp lệ.',
      );
    }
    return MapDataSource(
      source: source,
      label: label,
      file: file,
      count: count.toInt(),
      active: active,
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}'),
    );
  }
}

/// Finds nearby OpenStreetMap places, optionally through the local proxy.
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

  Future<int> preloadMapTiles() async {
    const centerLatitude = 10.46;
    const centerLongitude = 105.63;
    const zoom = 12;
    final scale = 1 << zoom;
    final centerX = ((centerLongitude + 180) / 360 * scale).floor();
    final latitudeRadians = centerLatitude * math.pi / 180;
    final centerY =
        ((1 -
                    math.log(
                          math.tan(latitudeRadians) +
                              (1 / math.cos(latitudeRadians)),
                        ) /
                        math.pi) /
                2 *
                scale)
            .floor();
    final requests = <Future<bool>>[];
    for (var x = centerX - 1; x <= centerX + 1; x++) {
      for (var y = centerY - 1; y <= centerY + 1; y++) {
        final subdomain = String.fromCharCode(
          'a'.codeUnitAt(0) + requests.length % 3,
        );
        requests.add(
          _client
              .get(
                Uri.parse(
                  'https://$subdomain.tile.openstreetmap.fr/hot/'
                  '$zoom/$x/$y.png',
                ),
              )
              .timeout(const Duration(seconds: 2))
              .then((response) => response.statusCode == 200)
              .catchError((_) => false),
        );
      }
    }
    final results = await Future.wait(requests);
    return results.where((loaded) => loaded).length;
  }

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

  Future<List<MapDataSource>> listMapDataSources() async {
    if (!_useProxy) {
      throw StateError('Chọn dữ liệu bản đồ cần chạy qua server Web local.');
    }
    final response = await _client
        .get(
          Uri.parse(
            '${_webBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/admin/map-sources',
          ),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'Không tải được danh sách dữ liệu bản đồ (${response.statusCode}).',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['sources'] is! List) {
      throw const FormatException('Danh sách dữ liệu bản đồ không hợp lệ.');
    }
    return [
      for (final item in decoded['sources'] as List)
        if (item is Map) MapDataSource.fromMap(item),
    ];
  }

  Future<int> selectMapDataSource(String source) async {
    if (!_useProxy) {
      throw StateError('Chọn dữ liệu bản đồ cần chạy qua server Web local.');
    }
    final response = await _client
        .post(
          Uri.parse(
            '${_webBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/admin/select-map',
          ),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'source': source}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Không chọn được dữ liệu bản đồ (${response.statusCode}).';
      throw Exception(message);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['count'] is! num) {
      throw const FormatException('Phản hồi chọn dữ liệu bản đồ không hợp lệ.');
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
        '["amenity"~"^(cafe|restaurant|fast_food|bar|pub|cinema|school|college|university|dormitory|bus_station)\$"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["leisure"~"^(park|playground|amusement_arcade|water_park|sports_centre|stadium)\$"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["shop"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["tourism"~"^(theme_park|zoo|museum|attraction|guest_house|hostel|hotel|motel|apartment|chalet|alpine_hut)\$"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["building"="dormitory"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["public_transport"="station"]["bus"="yes"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["highway"="bus_stop"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["public_transport"~"^(platform|stop_position)\$"]["bus"="yes"];'
        ');out center tags;';
    final uri = _useProxy
        ? Uri.parse('${_webBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/nearby')
        : Uri.https('overpass-api.de', '/api/interpreter');
    final http.Response response;
    try {
      response = await _client
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
    } on http.ClientException {
      return await _offlineSearch(center, radiusMeters);
    } on TimeoutException {
      return await _offlineSearch(center, radiusMeters);
    }

    if (response.statusCode != 200) {
      return await _offlineSearch(center, radiusMeters);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['elements'] is! List) {
      return await _offlineSearch(center, radiusMeters);
    }
    return _placesFromElements(decoded['elements'] as List, center);
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
    if (cached == null) {
      if (!_useProxy) {
        throw StateError(
          'Không kết nối được OpenStreetMap và chưa có dữ liệu offline.',
        );
      }
      throw StateError(
        'Backend địa điểm không khả dụng và chưa có dữ liệu offline. '
        'Hãy chạy run_web.bat hoặc bat_app.bat để khởi động backend tại '
        'localhost:8787.',
      );
    }
    final decoded = jsonDecode(cached);
    if (decoded is! List) {
      throw const FormatException('Dữ liệu địa điểm offline không hợp lệ.');
    }
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
    final name = foldVietnamese('${tags['name'] ?? tags['name:vi'] ?? ''}')
        .toLowerCase();
    if (name.contains('nha khach') ||
        name.contains('nha tro') ||
        name.contains('nha nghi') ||
        name.contains('ky tuc xa') ||
        name.contains('khach san') ||
        name.contains('hostel') ||
        name.contains('guest house')) {
      return 'tro';
    }
    if (name.contains('ben xe') ||
        name.contains('tram xe buyt') ||
        name.contains('diem dung xe buyt')) {
      return 'ben_xe';
    }
    if (name.contains('giao duc') ||
        name.contains('truong hoc') ||
        name.contains('hoc tap')) {
      return 'truong_hoc';
    }
    if (name.contains('cong vien') || name.contains(' park')) {
      return 'vui_choi';
    }

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
    if (const {
      'tro',
      'nha khach',
      'nha tro',
      'nha nghi',
      'ky tuc xa',
      'khach san',
      'guest_house',
      'hostel',
      'hotel',
      'motel',
      'apartment',
      'chalet',
      'alpine_hut',
      'dormitory',
    }.contains(localCategory)) {
      return 'tro';
    }
    if (const {'school', 'college', 'university'}.contains(localCategory)) {
      return 'truong_hoc';
    }
    if (const {
      'park',
      'playground',
      'amusement_arcade',
      'water_park',
      'sports_centre',
      'stadium',
    }.contains(localCategory)) {
      return 'vui_choi';
    }
    if (const {'bus_station', 'bus_stop', 'ben_xe'}.contains(localCategory)) {
      return 'ben_xe';
    }

    final amenity = '${tags['amenity'] ?? ''}';
    if (const {'school', 'college', 'university'}.contains(amenity)) {
      return 'truong_hoc';
    }
    if (const {'cafe'}.contains(amenity)) return 'cafe';
    if (const {'restaurant', 'fast_food'}.contains(amenity)) return 'quan_an';
    if (amenity == 'dormitory') return 'tro';
    if (amenity == 'bus_station' ||
        ('${tags['public_transport'] ?? ''}' == 'station' &&
            '${tags['bus'] ?? ''}' == 'yes')) {
      return 'ben_xe';
    }
    if ('${tags['highway'] ?? ''}' == 'bus_stop' ||
        (const {
              'platform',
              'stop_position',
            }.contains('${tags['public_transport'] ?? ''}') &&
            '${tags['bus'] ?? ''}' == 'yes')) {
      return 'ben_xe';
    }
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
    if (const {
      'guest_house',
      'hostel',
      'hotel',
      'motel',
      'apartment',
      'chalet',
      'alpine_hut',
    }.contains(tourism)) {
      return 'tro';
    }
    if ('${tags['building'] ?? ''}' == 'dormitory') return 'tro';

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
