import 'package:flutter/material.dart';

import '../map_tile_source.dart';

class MapStyleButton extends StatelessWidget {
  const MapStyleButton({
    required this.style,
    required this.onChanged,
    this.canUseSatellite = true,
    this.onRequireSignIn,
    super.key,
  });

  final MapStyle style;
  final ValueChanged<MapStyle> onChanged;
  final bool canUseSatellite;
  final VoidCallback? onRequireSignIn;

  @override
  Widget build(BuildContext context) {
    final locked = style == MapStyle.street && !canUseSatellite;
    return Positioned(
      top: 12,
      right: 12,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        child: Tooltip(
          message: locked
              ? 'Đăng nhập để xem ảnh vệ tinh'
              : style.switchTooltip,
          child: FilledButton.tonalIcon(
            onPressed: () {
              if (locked) {
                onRequireSignIn?.call();
                return;
              }
              onChanged(
                style == MapStyle.street ? MapStyle.satellite : MapStyle.street,
              );
            },
            icon: Icon(
              locked
                  ? Icons.lock_outline
                  : style == MapStyle.street
                  ? Icons.satellite_alt
                  : Icons.map_outlined,
            ),
            label: Text(
              locked
                  ? 'Đăng nhập để xem vệ tinh'
                  : style == MapStyle.street
                  ? 'Xem vệ tinh'
                  : 'Bản đồ thường',
            ),
          ),
        ),
      ),
    );
  }
}
