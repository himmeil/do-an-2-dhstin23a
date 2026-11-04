abstract final class AppLinks {
  static const nearbyApiBaseUrl = String.fromEnvironment(
    'NEARBY_API_BASE_URL',
  );
  static const overpassApiUrl = String.fromEnvironment('OVERPASS_API_URL');
  static const nominatimSearchUrl = String.fromEnvironment(
    'NOMINATIM_SEARCH_URL',
  );
  static const streetTileUrl = String.fromEnvironment('STREET_TILE_URL');
  static const satelliteTileUrl = String.fromEnvironment(
    'SATELLITE_TILE_URL',
  );
  static const directionsUrl = String.fromEnvironment('DIRECTIONS_URL');

  static String require(String name, String value) {
    if (value.isEmpty) {
      throw StateError(
        'Thiếu $name trong dulieucanhan.env. Hãy sao chép file mẫu và '
        'điền các liên kết dịch vụ cần dùng.',
      );
    }
    return value;
  }
}
