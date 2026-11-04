import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../map_tile_source.dart';

class VietnamIslandsMapInset extends StatefulWidget {
  const VietnamIslandsMapInset({super.key});

  @override
  State<VietnamIslandsMapInset> createState() => _VietnamIslandsMapInsetState();
}

class _VietnamIslandsMapInsetState extends State<VietnamIslandsMapInset> {
  bool _isVisible = true;
  late final _tileProvider = createCaoLanhTileProvider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned(
      right: 12,
      bottom: 42,
      child: _isVisible
          ? SizedBox(
              width: 188,
              height: 132,
              child: Stack(
                children: [
                  IgnorePointer(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          FlutterMap(
                            key: const ValueKey('vietnam-islands-inset-map'),
                            options: const MapOptions(
                              initialCenter: LatLng(13.2, 113.1),
                              initialZoom: 4,
                              interactionOptions: InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: MapStyle.street.tileUrl,
                                subdomains: const ['a', 'b', 'c'],
                                tileProvider: _tileProvider,
                                keepBuffer: 0,
                                panBuffer: 0,
                                tileDisplay: const TileDisplay.instantaneous(),
                                userAgentPackageName: 'vn.diadiem.quanhday',
                              ),
                              MarkerLayer(
                                markers: [
                                  _islandMarker(
                                    const LatLng(16.5, 112.0),
                                    colors,
                                  ),
                                  _islandMarker(
                                    const LatLng(10.0, 114.0),
                                    colors,
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 3,
                                left: 3,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.surface.withValues(
                                      alpha: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      '© OpenStreetMap contributors',
                                      style: TextStyle(fontSize: 8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: 4,
                            top: 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'Hoàng Sa, Trường Sa là của Việt Nam',
                                  style: TextStyle(
                                    fontSize: 9,
                                    height: 1.15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Material(
                      color: colors.surface.withValues(alpha: 0.94),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Ẩn bản đồ Hoàng Sa, Trường Sa',
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _isVisible = false),
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Material(
              color: colors.surface.withValues(alpha: 0.94),
              elevation: 3,
              borderRadius: BorderRadius.circular(24),
              child: IconButton(
                tooltip: 'Hiện bản đồ Hoàng Sa, Trường Sa',
                onPressed: () => setState(() => _isVisible = true),
                icon: const Icon(Icons.map_outlined),
              ),
            ),
    );
  }

  Marker _islandMarker(LatLng point, ColorScheme colors) => Marker(
    point: point,
    width: 14,
    height: 14,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
    ),
  );
}
