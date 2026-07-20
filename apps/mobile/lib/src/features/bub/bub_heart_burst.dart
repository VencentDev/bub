import 'dart:math' as math;

import 'package:flutter/material.dart';

class BubHeartBurst extends StatefulWidget {
  const BubHeartBurst({
    super.key,
    required this.trigger,
    this.heartKey = const Key('bub-heart-burst-heart'),
  });

  final int trigger;
  final Key heartKey;

  @override
  State<BubHeartBurst> createState() => _BubHeartBurstState();
}

class _BubHeartBurstState extends State<BubHeartBurst>
    with SingleTickerProviderStateMixin {
  static const _hearts = [
    _FloatingHeartSpec(x: 0.10, size: 24, delay: 0.00, drift: 24, turn: -0.18),
    _FloatingHeartSpec(x: 0.22, size: 38, delay: 0.08, drift: -18, turn: 0.16),
    _FloatingHeartSpec(x: 0.36, size: 28, delay: 0.16, drift: 34, turn: -0.10),
    _FloatingHeartSpec(x: 0.50, size: 46, delay: 0.04, drift: -8, turn: 0.08),
    _FloatingHeartSpec(x: 0.64, size: 30, delay: 0.18, drift: 22, turn: -0.16),
    _FloatingHeartSpec(x: 0.78, size: 40, delay: 0.10, drift: -30, turn: 0.14),
    _FloatingHeartSpec(x: 0.90, size: 26, delay: 0.22, drift: 16, turn: -0.08),
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
  }

  @override
  void didUpdateWidget(covariant BubHeartBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _controller.value = 0.001;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  for (final spec in _hearts)
                    _FloatingHeart(
                      spec: spec,
                      progress: _controller.value,
                      screenSize: constraints.biggest,
                      heartKey: widget.heartKey,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _FloatingHeart extends StatelessWidget {
  const _FloatingHeart({
    required this.spec,
    required this.progress,
    required this.screenSize,
    required this.heartKey,
  });

  final _FloatingHeartSpec spec;
  final double progress;
  final Size screenSize;
  final Key heartKey;

  @override
  Widget build(BuildContext context) {
    final localProgress = ((progress - spec.delay) / (1 - spec.delay)).clamp(
      0.0,
      1.0,
    );
    if (localProgress == 0 || localProgress == 1) {
      return const SizedBox.shrink();
    }

    final eased = Curves.easeOutCubic.transform(localProgress);
    final fade = localProgress < 0.72
        ? Curves.easeOut.transform((localProgress / 0.72).clamp(0.0, 1.0))
        : 1 -
              Curves.easeIn.transform(
                ((localProgress - 0.72) / 0.28).clamp(0.0, 1.0),
              );
    final baseLeft = screenSize.width * spec.x - spec.size / 2;
    final bottom = 104 + eased * (screenSize.height * 0.68);
    final left =
        baseLeft +
        math.sin(localProgress * math.pi * 1.6) * spec.drift +
        spec.drift * eased * 0.34;

    return Positioned(
      left: left,
      bottom: bottom,
      child: Opacity(
        opacity: fade,
        child: Transform.rotate(
          angle: spec.turn * math.sin(localProgress * math.pi),
          child: Transform.scale(
            scale: 0.72 + Curves.elasticOut.transform(localProgress) * 0.28,
            child: Image.asset(
              'assets/onboarding/heart.png',
              key: heartKey,
              width: spec.size,
              height: spec.size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingHeartSpec {
  const _FloatingHeartSpec({
    required this.x,
    required this.size,
    required this.delay,
    required this.drift,
    required this.turn,
  });

  final double x;
  final double size;
  final double delay;
  final double drift;
  final double turn;
}
