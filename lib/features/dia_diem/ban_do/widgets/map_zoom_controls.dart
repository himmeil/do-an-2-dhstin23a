import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    required this.controller,
    required this.enabled,
    this.minZoom = 11,
    this.maxZoom = 18,
    super.key,
  });

  final MapController controller;
  final bool enabled;
  final double minZoom;
  final double maxZoom;

  void _changeZoom(double amount) {
    final camera = controller.camera;
    final zoom = (camera.zoom + amount).clamp(minZoom, maxZoom).toDouble();
    if (zoom == camera.zoom) return;
    controller.move(camera.center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      top: 12,
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Tooltip(
              message: 'Phóng to bản đồ',
              child: IconButton(
                onPressed: enabled ? () => _changeZoom(1) : null,
                icon: const Icon(Icons.add),
              ),
            ),
            const Divider(height: 1),
            Tooltip(
              message: 'Thu nhỏ bản đồ',
              child: IconButton(
                onPressed: enabled ? () => _changeZoom(-1) : null,
                icon: const Icon(Icons.remove),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Zoom',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
