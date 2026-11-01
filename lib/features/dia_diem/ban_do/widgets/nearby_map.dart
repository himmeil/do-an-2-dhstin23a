import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../cao_lanh_ward_boundary.dart';
import '../map_tile_source.dart';
import 'map_source_attribution.dart';
import 'map_style_button.dart';
import '../../tim_kiem/widgets/place_tile.dart';

/// Bản đồ OpenStreetMap hiện các địa điểm tìm được và vị trí của người dùng.
class NearbyMap extends StatefulWidget {
  const NearbyMap({
    required this.hits,
    required this.origin,
    required this.onSelect,
    this.zoom = 15,
    super.key,
  });

  final List<PlaceHit> hits;
  final LatLng? origin;
  final ValueChanged<PlaceHit> onSelect;
  final double zoom;

  @override
  State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
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
          key: ValueKey(widget.origin),
          options: MapOptions(
            initialCenter: _center,
            initialZoom: widget.origin == null && widget.hits.isEmpty
                ? 11
                : widget.zoom,
          ),
          children: [
            TileLayer(
              urlTemplate: _style.tileUrl,
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
            MarkerLayer(
              markers: [
                if (widget.origin != null)
                  Marker(
                    point: widget.origin!,
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.my_location,
                      color: colors.primary,
                      size: 28,
                    ),
                  ),
                for (final hit in widget.hits)
                  Marker(
                    point: hit.place.latLng,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => widget.onSelect(hit),
                      child: Tooltip(
                        message: hit.place.name,
                        child: Icon(
                          Icons.location_pin,
                          size: 44,
                          color: colors.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            MapSourceAttribution(style: _style, includeOpenStreetMapData: true),
          ],
        ),
        MapStyleButton(
          style: _style,
          onChanged: (style) => setState(() => _style = style),
        ),
      ],
    );
  }
}
