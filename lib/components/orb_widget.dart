// lib/components/orb_widget.dart — VIDUR Design Module
// Companion's emotional connection orb using CustomPainter + flutter_animate

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vidur/core/contracts.dart';
import 'package:vidur/theme/theme.dart';

class OrbWidget extends StatefulWidget {
  final OrbState state;
  final double size;
  final bool isCompanionView;

  const OrbWidget({
    super.key,
    required this.state,
    this.size = 200,
    this.isCompanionView = false,
  });

  @override
  State<OrbWidget> createState() => _OrbWidgetState();
}

class _OrbWidgetState extends State<OrbWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _transitionController;
  late AnimationController _ringController;

  OrbState _currentState = OrbState.safe;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;

    _breathController = AnimationController(vsync: this)
      ..repeat(reverse: true);

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _applyState(widget.state, initial: true);
  }

  @override
  void didUpdateWidget(OrbWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _transitionController.forward(from: 0);
      _applyState(widget.state);
      setState(() => _currentState = widget.state);
    }
  }

  void _applyState(OrbState state, {bool initial = false}) {
    _breathController.stop();
    _ringController.stop();

    switch (state) {
      case OrbState.safe:
        _breathController.duration = const Duration(milliseconds: 2000);
        _breathController.repeat(reverse: true);
        break;
      case OrbState.paused:
        _breathController.duration = const Duration(milliseconds: 4000);
        _breathController.repeat(reverse: true);
        break;
      case OrbState.help:
        _breathController.duration = const Duration(milliseconds: 300);
        _breathController.repeat(reverse: true);
        break;
      case OrbState.arrived:
        _ringController.repeat();
        break;
    }
  }

  Color get _orbColor {
    switch (_currentState) {
      case OrbState.safe:
        return AppColors.navigateGold;   // #E8A020 — bright gold
      case OrbState.paused:
        return AppColors.watchGold;      // #C8A850 — dim gold
      case OrbState.help:
        return AppColors.alertRed;       // #E53935 — urgent red
      case OrbState.arrived:
        return AppColors.safeGreen;      // #4CAF50 — celebratory green
    }
  }

  Color get _glowColor {
    switch (_currentState) {
      case OrbState.safe:
        return AppColors.navigateGold.withOpacity(0.30);
      case OrbState.paused:
        return AppColors.watchGold.withOpacity(0.20);
      case OrbState.help:
        return AppColors.alertRed.withOpacity(0.45);
      case OrbState.arrived:
        return AppColors.safeGreen.withOpacity(0.30);
    }
  }

  double get _targetOpacity => _currentState == OrbState.paused ? 0.40 : 1.0;

  double get _orbScale {
    if (_currentState == OrbState.safe && widget.isCompanionView) return 0.65;
    return 0.70;
  }

  @override
  void dispose() {
    _breathController.dispose();
    _transitionController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(alignment: Alignment.center, children: [
        // Expanding arrival rings
        if (_currentState == OrbState.arrived)
          AnimatedBuilder(
            animation: _ringController,
            builder: (_, __) => CustomPaint(
              size: Size(s, s),
              painter: _ArrivalRingPainter(_ringController.value, AppColors.safeGreen),
            ),
          ),

        // Paused: static grey outer ring
        if (_currentState == OrbState.paused)
          CustomPaint(
            size: Size(s, s),
            painter: _StaticRingPainter(AppColors.textSecondary.withOpacity(0.35)),
          ),

        // Main orb body
        AnimatedBuilder(
          animation: _breathController,
          builder: (_, child) {
            final scale = 0.95 + (_breathController.value * 0.10);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: AnimatedOpacity(
            opacity: _targetOpacity,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: s * _orbScale,
              height: s * _orbScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orbColor,
                // Companion safe state: thin gold border ring
                border: (_currentState == OrbState.safe && widget.isCompanionView)
                    ? Border.all(
                        color: AppColors.navigateGold.withOpacity(0.70),
                        width: 1.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: _glowColor,
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                  // Help state: second urgent glow layer
                  if (_currentState == OrbState.help)
                    BoxShadow(
                      color: AppColors.alertRed.withOpacity(0.25),
                      blurRadius: 60,
                      spreadRadius: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
      ]),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.85, 0.85), duration: 400.ms);
  }
}

class _ArrivalRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArrivalRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = ((progress - i * 0.25) % 1.0).clamp(0.0, 1.0);
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0);
      final radius = maxRadius * 0.3 + (maxRadius * 0.7 * ringProgress);

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ArrivalRingPainter old) =>
      old.progress != progress || old.color != color;
}

class _StaticRingPainter extends CustomPainter {
  final Color color;

  _StaticRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.88;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_StaticRingPainter old) => old.color != color;
}
