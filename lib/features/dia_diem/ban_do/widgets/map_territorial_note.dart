import 'package:flutter/material.dart';

class MapTerritorialNote extends StatelessWidget {
  const MapTerritorialNote({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned(
      left: 10,
      bottom: 30,
      child: Material(
        color: colors.surface.withValues(alpha: 0.94),
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 6),
              const Text(
                'Hoàng Sa, Trường Sa là của Việt Nam',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
