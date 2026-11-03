import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

class StartupSplash extends StatefulWidget {
  const StartupSplash({required this.child, this.onPrepare, super.key});

  final Widget child;
  final Future<void> Function()? onPrepare;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  static const _progressFraction = 1000 / 2350;
  static const _enteringAppFraction = 2000 / 2350;

  late final AnimationController _startupController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2350),
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _startupController,
    curve: const Interval(0, _progressFraction),
  );
  late final Animation<double> _fade = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(
      parent: _startupController,
      curve: const Interval(_enteringAppFraction, 1),
    ),
  );

  bool _showSplash = true;
  bool _isComplete = false;
  bool _isEnteringApp = false;
  bool _isPreparing = false;

  @override
  void initState() {
    super.initState();
    _startupController.addListener(() {
      if (!_isEnteringApp &&
          _startupController.value >= _progressFraction &&
          mounted) {
        setState(() => _isEnteringApp = true);
      }
    });
    _startupController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showSplash = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isComplete = true);
      _prepareAndStart();
    });
  }

  Future<void> _prepareAndStart() async {
    if (widget.onPrepare != null) {
      if (mounted) setState(() => _isPreparing = true);
      try {
        await widget.onPrepare!().timeout(const Duration(seconds: 4));
      } catch (_) {
        // The local cache is optional; the app can still use Firestore.
      }
      if (!mounted) return;
      setState(() => _isPreparing = false);
    }
    if (mounted) _startupController.forward();
  }

  @override
  void dispose() {
    _startupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_showSplash)
          Positioned.fill(
            child: FadeTransition(
              key: const ValueKey('startup-splash'),
              opacity: _fade,
              child: IgnorePointer(
                child: _SplashArtwork(
                  progress: _progress,
                  isComplete: _isComplete,
                  isEnteringApp: _isEnteringApp,
                  isPreparing: _isPreparing,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SplashArtwork extends StatelessWidget {
  const _SplashArtwork({
    required this.progress,
    required this.isComplete,
    required this.isEnteringApp,
    required this.isPreparing,
  });

  final Animation<double> progress;
  final bool isComplete;
  final bool isEnteringApp;
  final bool isPreparing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/splash/launch.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xB3000000)],
              stops: [0.55, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 180,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedBuilder(
                          animation: progress,
                          builder: (context, _) => Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 22,
                                child: LinearProgressIndicator(
                                  value: progress.value == 0
                                      ? null
                                      : progress.value,
                                  minHeight: 22,
                                  backgroundColor: const Color(0xFFEBF2FA),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF70A1FF),
                                      ),
                                ),
                              ),
                              if (progress.value == 0)
                                const Positioned.fill(
                                  child: _IndeterminateShimmer(),
                                ),
                              if (isComplete)
                                Text(
                                  '${(progress.value * 100).floor()}%',
                                  key: const ValueKey('startup-splash-percent'),
                                  style: const TextStyle(
                                    color: Color(0xFF17324D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _LoadingStatus(
                          isComplete: isComplete,
                          isEnteringApp: isEnteringApp,
                          isPreparing: isPreparing,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  const _LoadingStatus({
    required this.isComplete,
    required this.isEnteringApp,
    required this.isPreparing,
  });

  final bool isComplete;
  final bool isEnteringApp;
  final bool isPreparing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isPreparing
              ? 'ĐANG TẢI DỮ LIỆU BẢN ĐỒ'
              : isEnteringApp
              ? 'ĐANG VÀO APP'
              : isComplete
              ? 'HOÀN THÀNH'
              : 'ĐANG KHỞI TẠO',
          style: const TextStyle(
            color: Color(0xFFBBF7D0),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 3),
        const _BouncingDots(),
      ],
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final phase = (_controller.value - index / 3) * 2 * math.pi;
          final offset = -4.0 * math.max(0.0, math.sin(phase));
          return Transform.translate(
            offset: Offset(0, offset),
            child: const Text(
              '.',
              style: TextStyle(
                color: Color(0xFFBBF7D0),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _IndeterminateShimmer extends StatefulWidget {
  const _IndeterminateShimmer();

  @override
  State<_IndeterminateShimmer> createState() => _IndeterminateShimmerState();
}

class _IndeterminateShimmerState extends State<_IndeterminateShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Align(
        alignment: Alignment(-1.7 + (_controller.value * 3.4), 0),
        child: child,
      ),
      child: FractionallySizedBox(
        widthFactor: 0.35,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0xFF70A1FF),
            boxShadow: const [
              BoxShadow(color: Color(0x8C70A1FF), blurRadius: 10),
            ],
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
