import 'package:flutter/material.dart';

class LotusMascot extends StatefulWidget {
  const LotusMascot({
    this.outfitId,
    this.semanticLabel = 'Nhân vật hoa sen đang chuyển động',
    super.key,
  });

  final String? outfitId;
  final String semanticLabel;

  @override
  State<LotusMascot> createState() => _LotusMascotState();
}

class _LotusMascotState extends State<LotusMascot>
    with SingleTickerProviderStateMixin {
  static const _frameCount = 6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 960),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outfit = widget.outfitId ?? 'lotus';
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final frame = (_controller.value * _frameCount).floor() % _frameCount;
        return Image.asset(
          'assets/mini_game/characters/lotus/idle/$outfit/frame_${frame.toString().padLeft(2, '0')}.png',
          key: ValueKey('lotus-mascot-frame-$frame-$outfit'),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          semanticLabel: widget.semanticLabel,
        );
      },
    );
  }
}
