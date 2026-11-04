import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/display_preferences.dart';

class DisplaySettingsSheet extends StatefulWidget {
  const DisplaySettingsSheet({
    required this.graphicsQuality,
    required this.animationsEnabled,
    required this.onGraphicsQualityChanged,
    required this.onAnimationsChanged,
    super.key,
  });

  final MapGraphicsQuality graphicsQuality;
  final bool animationsEnabled;
  final Future<bool> Function(MapGraphicsQuality) onGraphicsQualityChanged;
  final Future<bool> Function(bool) onAnimationsChanged;

  @override
  State<DisplaySettingsSheet> createState() => _DisplaySettingsSheetState();
}

class _DisplaySettingsSheetState extends State<DisplaySettingsSheet> {
  late MapGraphicsQuality _graphicsQuality;
  late bool _animationsEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _graphicsQuality = widget.graphicsQuality;
    _animationsEnabled = widget.animationsEnabled;
  }

  Future<void> _changeGraphicsQuality(MapGraphicsQuality quality) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.onGraphicsQualityChanged(quality);
      if (saved && mounted) setState(() => _graphicsQuality = quality);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeAnimations(bool enabled) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.onAnimationsChanged(enabled);
      if (saved && mounted) setState(() => _animationsEnabled = enabled);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hiển thị', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hiệu ứng chuyển động'),
            subtitle: const Text('Chuyển cảnh giữa bản đồ và danh sách'),
            value: _animationsEnabled,
            onChanged: _saving
                ? null
                : (enabled) => unawaited(_changeAnimations(enabled)),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Chất lượng đồ họa bản đồ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<MapGraphicsQuality>(
            groupValue: _graphicsQuality,
            onChanged: (value) {
              if (value != null && !_saving) {
                unawaited(_changeGraphicsQuality(value));
              }
            },
            child: Column(
              children: [
                for (final quality in MapGraphicsQuality.values)
                  RadioListTile<MapGraphicsQuality>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(quality.label),
                    subtitle: Text(quality.description),
                    value: quality,
                    enabled: !_saving,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
