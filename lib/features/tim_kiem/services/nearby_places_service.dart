import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError, kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_links.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/utils/text_utils.dart';
import '../../dia_diem/du_lieu/models/place.dart';
import '../../dia_diem/du_lieu/models/place_category_registry.dart';
import 'admin_error_log_service.dart';
import '../utils/geo.dart';

String _defaultNearbyApiBaseUrl() {
  if (AppEnvironment.isFirebaseHosted) {
    final configuredUrl = AppLinks.nearbyApiBaseUrl;
    if (configuredUrl.isNotEmpty) {
      final configuredUri = Uri.tryParse(configuredUrl);
      if (configuredUri != null &&
          !AppEnvironment.isLocalHost(configuredUri.host)) {
        return configuredUrl;
      }
    }
    return Uri.base.origin;
  }
  return AppLinks.require('NEARBY_API_BASE_URL', AppLinks.nearbyApiBaseUrl);
}

abstract interface class NearbyPlacesService {
  Future<List<Place>> search({
    required LatLng center,
    required int radiusMeters,
  });
}

class NearbyPlacesFailure implements Exception {
  const NearbyPlacesFailure(this.code, this.message);

  final AdminErrorCode code;
  final String message;

  @override
  String toString() => '${code.value}: $message';
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

class MapSnapshotMetadata {
  const MapSnapshotMetadata({required this.count, this.updatedAt});

  final int count;
  final DateTime? updatedAt;
}

/// Finds nearby OpenStreetMap places, optionally through the local proxy.
class OverpassNearbyPlacesService implements NearbyPlacesService {
  OverpassNearbyPlacesService({
    http.Client? client,
    String? webBaseUrl,
    bool? useProxy,
    bool? useStaticSnapshot,
    this.loadStaticSnapshot,
    this.getIdToken,
  }) : _client = client ?? http.Client(),
       _webBaseUrl = webBaseUrl ?? _defaultNearbyApiBaseUrl(),
       _useProxy = useProxy ?? kIsWeb,
       _useStaticSnapshot =
           useStaticSnapshot ?? AppEnvironment.isFirebaseHosted;

  final http.Client _client;
  final String _webBaseUrl;
  final bool _useProxy;
  final bool _useStaticSnapshot;
  final Future<String> Function()? loadStaticSnapshot;
  final Future<String?> Function()? getIdToken;
  Future<List<dynamic>>? _staticSnapshotElements;
  DateTime? _staticSnapshotUpdatedAt;
  static const offlineCacheKey = 'nearby_places_sql_download_v1';

  Future<MapSnapshotMetadata> staticSnapshotMetadata() async {
    final elements = await (_staticSnapshotElements ??= _readStaticSnapshot());
    return MapSnapshotMetadata(
      count: elements.length,
      updatedAt: _staticSnapshotUpdatedAt,
    );
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
          headers: await _adminHeaders(),
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
          headers: await _adminHeaders(),
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
          headers: await _adminHeaders(json: true),
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

  Future<Map<String, String>> _adminHeaders({bool json = false}) async {
    final token = await getIdToken?.call();
    if (token == null || token.isEmpty) {
      throw StateError('Cần đăng nhập trước khi thao tác quản trị.');
    }
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
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

    if (_useStaticSnapshot) {
      return _searchStaticSnapshot(center, radiusMeters);
    }

    final query =
        '[out:json][timeout:20];'
        '('
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["amenity"~"^(cafe|restaurant|fast_food|bar|pub|cinema|school|college|university|dormitory|bus_station)\$"];'
        'nwr(around:$radiusMeters,${center.latitude},${center.longitude})'
        '["leisure"~"^(park|playground|amusement_arcade|water_park|sports_centre|stadium|pitch|fitness_centre|swimming_pool)\$"];'
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
        : Uri.parse(
            AppLinks.require('OVERPASS_API_URL', AppLinks.overpassApiUrl),
          );
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

    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return await _offlineSearch(center, radiusMeters);
    }
    if (decoded is! Map || decoded['elements'] is! List) {
      return await _offlineSearch(center, radiusMeters);
    }
    return _placesFromElements(decoded['elements'] as List, center);
  }

  Future<List<Place>> _searchStaticSnapshot(
    LatLng center,
    int radiusMeters,
  ) async {
    final elements = await (_staticSnapshotElements ??= _readStaticSnapshot());
    return _placesFromElements(elements, center)
        .where((place) => distanceMeters(center, place.latLng) <= radiusMeters)
        .toList(growable: false);
  }

  Future<List<dynamic>> _readStaticSnapshot() async {
    final String contents;
    try {
      contents =
          await (loadStaticSnapshot?.call() ??
              rootBundle.loadString('assets/data/osm_places.json'));
    } on FlutterError {
      throw const NearbyPlacesFailure(
        AdminErrorCode.nearbySnapshotReadFailed,
        'Không tìm thấy snapshot bản đồ OpenStreetMap trong bản build.',
      );
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException {
      throw const NearbyPlacesFailure(
        AdminErrorCode.nearbySnapshotReadFailed,
        'Dữ liệu bản đồ OpenStreetMap không đúng định dạng.',
      );
    }
    if (decoded is! Map || decoded['elements'] is! List) {
      throw const NearbyPlacesFailure(
        AdminErrorCode.nearbySnapshotReadFailed,
        'Snapshot bản đồ OpenStreetMap không có danh sách địa điểm hợp lệ.',
      );
    }
    _staticSnapshotUpdatedAt = DateTime.tryParse(
      '${decoded['updatedAt'] ?? ''}',
    );
    return decoded['elements'] as List<dynamic>;
  }

  List<Place> _placesFromElements(List elements, LatLng center) {
    final places = <Place>[];
    for (final element in elements) {
      if (element is! Map || element['tags'] is! Map) continue;
      final tags = Map<String, dynamic>.from(element['tags'] as Map);
      if (!_isSearchableOsmPlace(tags)) continue;
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
        AppEnvironment.isFirebaseHosted
            ? 'Dịch vụ địa điểm trực tuyến chưa được cấu hình trên máy chủ này.'
            : 'Backend địa điểm không khả dụng và chưa có dữ liệu offline. '
                  'Hãy chạy run_web.bat hoặc bat_app.bat để khởi động backend '
                  'tại localhost:8787.',
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
      if (!_isSearchableOsmPlace(tags)) continue;
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

  bool _isSearchableOsmPlace(Map<String, dynamic> tags) {
    final highway = '${tags['highway'] ?? ''}'.trim();
    if (highway.isEmpty || highway == 'bus_stop' || highway == 'platform') {
      return true;
    }
    return const [
      'amenity',
      'shop',
      'leisure',
      'tourism',
      'public_transport',
      'historic',
      'building',
      'place',
    ].any((key) => tags[key] != null && '${tags[key]}'.trim().isNotEmpty);
  }

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
    final normalizedCategory = categoryOf(localCategory).code;
    if (normalizedCategory != 'khac') return normalizedCategory;
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
      'pitch',
      'fitness_centre',
      'swimming_pool',
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
      'pitch',
      'fitness_centre',
      'swimming_pool',
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
