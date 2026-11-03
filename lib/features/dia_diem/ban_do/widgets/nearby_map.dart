import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../cao_lanh_ward_boundary.dart';
import '../map_tile_source.dart';
import '../../du_lieu/models/place_category.dart';
import 'map_source_attribution.dart';
import 'map_style_button.dart';
import 'map_zoom_controls.dart';
import 'vietnam_islands_map_inset.dart';
import '../../tim_kiem/widgets/place_tile.dart';

/// Bản đồ OpenStreetMap hiện các địa điểm tìm được và vị trí của người dùng.
class NearbyMap extends StatefulWidget {
  const NearbyMap({
    required this.hits,
    required this.origin,
    required this.onSelect,
    this.selectedPlaceId,
    this.onChooseOrigin,
    this.onZoomChanged,
    this.canUseSatellite = true,
    this.onRequireSignIn,
    this.zoom = 15,
    this.radiusKm,
    this.showTerritorialInfo = true,
    super.key,
  });

  final List<PlaceHit> hits;
  final LatLng? origin;
  final ValueChanged<PlaceHit> onSelect;
  final String? selectedPlaceId;
  final ValueChanged<LatLng>? onChooseOrigin;
  final ValueChanged<double>? onZoomChanged;
  final bool canUseSatellite;
  final VoidCallback? onRequireSignIn;
  final double zoom;
  final double? radiusKm;
  final bool showTerritorialInfo;

  @override
  State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
  static const _minZoom = 11.0;
  static const _maxZoom = 18.0;
  static const _markerZoomThreshold = _minZoom + (_maxZoom - _minZoom) * 0.96;
  static const _maxVisibleMarkers = 300;
  MapStyle _style = MapStyle.street;
  late double _currentZoom;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoom;
  }

  @override
  void didUpdateWidget(covariant NearbyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlaceId != oldWidget.selectedPlaceId &&
        widget.selectedPlaceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final selected = widget.hits
            .where((hit) => hit.place.id == widget.selectedPlaceId)
            .firstOrNull;
        if (selected == null) return;
        _mapController.move(selected.place.latLng, _maxZoom);
      });
    } else if (widget.origin != oldWidget.origin && widget.origin != null) {
      final origin = widget.origin!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(origin, _currentZoom);
      });
    }
  }

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
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: widget.origin == null && widget.hits.isEmpty
                ? 11
                : widget.zoom,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            cameraConstraint: CameraConstraint.contain(
              bounds: caoLanhMapBounds,
            ),
            onPositionChanged: (camera, _) {
              widget.onZoomChanged?.call(camera.zoom);
              final wasShowingMarkers = _currentZoom >= _markerZoomThreshold;
              final isShowingMarkers = camera.zoom >= _markerZoomThreshold;
              if (wasShowingMarkers != isShowingMarkers) {
                setState(() => _currentZoom = camera.zoom);
              } else {
                _currentZoom = camera.zoom;
              }
            },
            onMapReady: () => widget.onZoomChanged?.call(
              widget.origin == null && widget.hits.isEmpty ? 11 : widget.zoom,
            ),
            onLongPress: (_, point) => widget.onChooseOrigin?.call(point),
          ),
          children: [
            TileLayer(
              urlTemplate: _style.tileUrl,
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'vn.diadiem.quanhday',
            ),
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
                      Icons.location_pin,
                      color: colors.primary,
                      size: 28,
                    ),
                  ),
                if (_currentZoom >= _markerZoomThreshold)
                  for (final hit in widget.hits.take(_maxVisibleMarkers))
                    Marker(
                      point: hit.place.latLng,
                      width: 26,
                      height: 26,
                      child: GestureDetector(
                        onTap: () => widget.onSelect(hit),
                        child: Tooltip(
                          message: hit.place.name,
                          child: Icon(
                            categoryOf(hit.place.category).icon,
                            size: 22,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                for (final hit in widget.hits)
                  if (hit.place.id == widget.selectedPlaceId)
                    Marker(
                      point: hit.place.latLng,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => widget.onSelect(hit),
                        child: Icon(
                          Icons.location_pin,
                          size: 40,
                          color: colors.error,
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
        MapZoomControls(controller: _mapController),
      ],
    );
  }
}
