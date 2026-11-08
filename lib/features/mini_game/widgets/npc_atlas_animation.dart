import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NpcAtlasFrame {
  const NpcAtlasFrame(
    this.x,
    this.y,
    this.width,
    this.height, {
    this.rotated = false,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final bool rotated;
}

const teacherAnswerFrames = <NpcAtlasFrame>[
  NpcAtlasFrame(0, 244, 82, 134, rotated: true),
  NpcAtlasFrame(400, 246, 82, 142, rotated: true),
  NpcAtlasFrame(264, 328, 84, 132, rotated: true),
  NpcAtlasFrame(818, 164, 82, 134, rotated: true),
  NpcAtlasFrame(132, 328, 84, 132, rotated: true),
  NpcAtlasFrame(542, 164, 82, 134, rotated: true),
  NpcAtlasFrame(0, 326, 84, 132, rotated: true),
  NpcAtlasFrame(132, 162, 82, 134, rotated: true),
  NpcAtlasFrame(134, 244, 84, 132, rotated: true),
  NpcAtlasFrame(676, 164, 82, 142, rotated: true),
  NpcAtlasFrame(0, 80, 82, 138, rotated: true),
];

const teacherVictoryFrames = <NpcAtlasFrame>[
  NpcAtlasFrame(676, 0, 82, 138, rotated: true),
  NpcAtlasFrame(276, 412, 88, 138, rotated: true),
  NpcAtlasFrame(138, 412, 86, 138, rotated: true),
  NpcAtlasFrame(672, 328, 84, 138, rotated: true),
  NpcAtlasFrame(694, 414, 88, 140, rotated: true),
  NpcAtlasFrame(534, 328, 84, 138, rotated: true),
  NpcAtlasFrame(554, 412, 88, 140, rotated: true),
  NpcAtlasFrame(396, 328, 84, 138, rotated: true),
  NpcAtlasFrame(414, 412, 88, 140, rotated: true),
  NpcAtlasFrame(0, 412, 86, 138, rotated: true),
  NpcAtlasFrame(834, 414, 90, 140, rotated: true),
  NpcAtlasFrame(398, 0, 82, 138, rotated: true),
];

const chestClosedFrame = NpcAtlasFrame(0, 674, 70, 60);
const chestOpeningFrames = <NpcAtlasFrame>[
  NpcAtlasFrame(0, 308, 70, 62),
  NpcAtlasFrame(0, 242, 70, 66),
  NpcAtlasFrame(0, 170, 72, 76, rotated: true),
  NpcAtlasFrame(0, 84, 80, 86),
  NpcAtlasFrame(0, 0, 84, 84),
];

class NpcAtlasAnimation extends StatefulWidget {
  const NpcAtlasAnimation({
    required this.assetPath,
    required this.frames,
    required this.duration,
    required this.semanticLabel,
    super.key,
  }) : assert(frames.length > 0);

  final String assetPath;
  final List<NpcAtlasFrame> frames;
  final Duration duration;
  final String semanticLabel;

  @override
  State<NpcAtlasAnimation> createState() => _NpcAtlasAnimationState();
}

class _NpcAtlasAnimationState extends State<NpcAtlasAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final Future<ui.Image> _imageFuture = _loadImage();
  ui.Image? _image;

  Future<ui.Image> _loadImage() async {
    final data = await rootBundle.load(widget.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      final image = (await codec.getNextFrame()).image;
      if (mounted) {
        _image = image;
      } else {
        image.dispose();
      }
      return image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: FutureBuilder<ui.Image>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          }
          final image = snapshot.data;
          if (image == null) {
            return const SizedBox.expand();
          }
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final frameIndex = (_controller.value * widget.frames.length)
                  .floor()
                  .clamp(0, widget.frames.length - 1);
              return CustomPaint(
                painter: _NpcAtlasFramePainter(
                  image,
                  widget.frames[frameIndex],
                ),
                child: const SizedBox.expand(),
              );
            },
          );
        },
      ),
    );
  }
}

class _NpcAtlasFramePainter extends CustomPainter {
  const _NpcAtlasFramePainter(this.image, this.frame);

  final ui.Image image;
  final NpcAtlasFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = frame.rotated ? frame.height : frame.width;
    final frameHeight = frame.rotated ? frame.width : frame.height;
    final scale = math.min(size.width / frameWidth, size.height / frameHeight);
    if (!scale.isFinite || scale <= 0) return;

    final source = Rect.fromLTWH(frame.x, frame.y, frame.width, frame.height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (frame.rotated) canvas.rotate(-math.pi / 2);
    canvas.drawImageRect(
      image,
      source,
      Rect.fromCenter(
        center: Offset.zero,
        width: frame.width * scale,
        height: frame.height * scale,
      ),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NpcAtlasFramePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.frame != frame;
}
