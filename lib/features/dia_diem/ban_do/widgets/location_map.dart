import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../map_tile_source.dart';
import 'map_source_attribution.dart';
import 'map_style_button.dart';
import 'map_territorial_note.dart';
import 'map_zoom_controls.dart';

/// Đường dẫn chỉ đường tới tọa độ (mở bằng app/website Google Maps, không cần API key).
Uri directionsUri(double latitude, double longitude) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': '$latitude,$longitude'},
);

typedef OpenUrl = Future<bool> Function(Uri uri);

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Bản đồ OpenStreetMap có ghim 1 vị trí kèm nút "Chỉ đường".
/// Dùng OpenStreetMap vì Google Maps Platform không bán cho tài khoản thanh toán tại Việt Nam.
class LocationMap extends StatefulWidget {
  const LocationMap({
    required this.latitude,
    required this.longitude,
    this.height = 220,
    this.openUrl = _launchExternal,
    this.canUseSatellite = true,
    this.onRequireSignIn,
    super.key,
  });

  final double latitude;
  final double longitude;
  final double height;
  final OpenUrl openUrl;
  final bool canUseSatellite;
  final VoidCallback? onRequireSignIn;

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  MapStyle _style = MapStyle.street;
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final point = LatLng(widget.latitude, widget.longitude);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 16,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _style.tileUrl,
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'vn.diadiem.quanhday',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_pin,
                            size: 44,
                            color: colors.error,
                          ),
                        ),
                      ],
                    ),
                    MapSourceAttribution(style: _style),
                  ],
                ),
                const MapTerritorialNote(),
                MapStyleButton(
                  style: _style,
                  canUseSatellite: widget.canUseSatellite,
                  onRequireSignIn: widget.onRequireSignIn,
                  onChanged: (style) => setState(() => _style = style),
                ),
                MapZoomControls(
                  controller: _mapController,
                  minZoom: 12,
                  maxZoom: 19,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              widget.openUrl(directionsUri(widget.latitude, widget.longitude)),
          icon: const Icon(Icons.directions_outlined),
          label: const Text('Chỉ đường'),
        ),
      ],
    );
  }
}
