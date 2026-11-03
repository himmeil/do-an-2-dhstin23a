import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../map_tile_source.dart';

class MapSourceAttribution extends StatelessWidget {
  const MapSourceAttribution({
    required this.style,
    this.includeOpenStreetMapData = false,
    super.key,
  });

  final MapStyle style;
  final bool includeOpenStreetMapData;

  @override
  Widget build(BuildContext context) {
    if (style == MapStyle.street) {
      return const SimpleAttributionWidget(
        source: Text('OpenStreetMap HOT contributors'),
      );
    }
    return RichAttributionWidget(
      attributions: [
        const TextSourceAttribution(
          'Esri, Maxar, Earthstar Geographics, and the GIS User Community',
        ),
        if (includeOpenStreetMapData)
          const TextSourceAttribution('OpenStreetMap contributors'),
      ],
    );
  }
}
