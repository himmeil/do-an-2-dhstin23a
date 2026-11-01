import 'package:flutter/material.dart';

import '../map_tile_source.dart';

class MapStyleButton extends StatelessWidget {
  const MapStyleButton({
    required this.style,
    required this.onChanged,
    super.key,
  });

  final MapStyle style;
  final ValueChanged<MapStyle> onChanged;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 12,
    right: 12,
    child: Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: Tooltip(
        message: style.switchTooltip,
        child: FilledButton.tonalIcon(
          onPressed: () => onChanged(
            style == MapStyle.street ? MapStyle.satellite : MapStyle.street,
          ),
          icon: Icon(
            style == MapStyle.street ? Icons.satellite_alt : Icons.map_outlined,
          ),
          label: Text(
            style == MapStyle.street ? 'Xem vệ tinh' : 'Bản đồ thường',
          ),
        ),
      ),
    ),
  );
}
