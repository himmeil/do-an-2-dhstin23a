import 'package:flutter_map/flutter_map.dart';

import '../../../core/config/app_links.dart';

TileProvider createCaoLanhTileProvider() => NetworkTileProvider(
  cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
    maxCacheSize: 128 * 1024 * 1024,
  ),
);

enum MapStyle { street, satellite }

extension MapStyleSource on MapStyle {
  String get tileUrl => switch (this) {
    MapStyle.street =>
      AppLinks.require('STREET_TILE_URL', AppLinks.streetTileUrl),
    MapStyle.satellite =>
      AppLinks.require('SATELLITE_TILE_URL', AppLinks.satelliteTileUrl),
  };

  String get switchTooltip => switch (this) {
    MapStyle.street => 'Chuyển sang ảnh vệ tinh',
    MapStyle.satellite => 'Chuyển sang bản đồ đường phố',
  };
}
