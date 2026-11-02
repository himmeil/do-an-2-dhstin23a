import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../cao_lanh_ward_boundary.dart';
import '../map_tile_source.dart';
import '../../du_lieu/models/place_category.dart';
import 'foreign_countries_layer.dart';
import 'map_source_attribution.dart';
import 'map_style_button.dart';
import 'vietnam_islands_map_inset.dart';
import '../../tim_kiem/widgets/place_tile.dart';

/// Bản đồ OpenStreetMap hiện các địa điểm tìm được và vị trí của người dùng.
class NearbyMap extends StatefulWidget {
  const NearbyMap({
    required this.hits,
    required this.origin,
    required this.onSelect,
    this.onChooseOrigin,
    this.onZoomChanged,
    this.isManualOrigin = false,
    this.canUseSatellite = true,
    this.onRequireSignIn,
    this.zoom = 15,
    this.radiusKm,
    this.showTerritorialInfo = true,
    this.simplifyForeignCountries = false,
    super.key,
  });

  final List<PlaceHit> hits;
  final LatLng? origin;
  final ValueChanged<PlaceHit> onSelect;
  final ValueChanged<LatLng>? onChooseOrigin;
  final ValueChanged<double>? onZoomChanged;
  final bool isManualOrigin;
  final bool canUseSatellite;
  final VoidCallback? onRequireSignIn;
  final double zoom;
  final double? radiusKm;
  final bool showTerritorialInfo;
  final bool simplifyForeignCountries;

  @override
  State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
  static const _maxZoom = 18.0;
  MapStyle _style = MapStyle.street;

  LatLng get _center {
    if (widget.origin != null) return widget.origin!;
    if (widget.hits.isNotEmpty) return widget.hits.first.place.latLng;
    return caoLanhWardCenter;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        FlutterMap(
          // Đổi key khi có vị trí mới để bản đồ dịch về đúng chỗ.
          key: const ValueKey('nearby-map-main'),
          options: MapOptions(
            initialCenter: _center,
            initialZoom: widget.origin == null && widget.hits.isEmpty
                ? 11
                : widget.zoom,
            minZoom: 11,
            maxZoom: _maxZoom,
            cameraConstraint: CameraConstraint.contain(
              bounds: caoLanhMapBounds,
            ),
            onPositionChanged: (camera, _) =>
                widget.onZoomChanged?.call(camera.zoom),
            onMapReady: () => widget.onZoomChanged?.call(
              widget.origin == null && widget.hits.isEmpty ? 11 : widget.zoom,
            ),
            onLongPress: (_, point) => widget.onChooseOrigin?.call(point),
          ),
          children: [
            TileLayer(
              urlTemplate: _style.tileUrl,
              userAgentPackageName: 'vn.diadiem.quanhday',
            ),
            if (widget.simplifyForeignCountries) const ForeignCountriesLayer(),
            PolygonLayer(
              polygons: [
                Polygon(
                  points: caoLanhWardBoundary,
                  color: colors.primary.withValues(alpha: 0.12),
                  borderColor: colors.primary,
                  borderStrokeWidth: 3,
                ),
              ],
            ),
            if (widget.origin != null && widget.radiusKm != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.origin!,
                    radius: widget.radiusKm! * 1000,
                    useRadiusInMeter: true,
                    color: colors.primary.withValues(alpha: 0.09),
                    borderColor: colors.primary.withValues(alpha: 0.75),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (widget.origin != null)
                  Marker(
                    point: widget.origin!,
                    width: 28,
                    height: 28,
                    child: Icon(
                      widget.isManualOrigin
                          ? Icons.location_pin
                          : Icons.my_location,
                      color: colors.primary,
                      size: 28,
                    ),
                  ),
                for (final hit in widget.hits)
                  Marker(
                    point: hit.place.latLng,
                    width: 42,
                    height: 42,
                    child: GestureDetector(
                      onTap: () => widget.onSelect(hit),
                      child: Tooltip(
                        message: hit.place.name,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.primary, width: 2),
                            boxShadow: const [
                              BoxShadow(blurRadius: 4, color: Colors.black26),
                            ],
                          ),
                          child: Icon(
                            categoryOf(hit.place.category).icon,
                            size: 24,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            MapSourceAttribution(style: _style, includeOpenStreetMapData: true),
          ],
        ),
        if (widget.showTerritorialInfo) const VietnamIslandsMapInset(),
        MapStyleButton(
          style: _style,
          canUseSatellite: widget.canUseSatellite,
          onRequireSignIn: widget.onRequireSignIn,
          onChanged: (style) => setState(() => _style = style),
        ),
      ],
    );
  }
}
