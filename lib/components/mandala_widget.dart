// lib/components/mandala_widget.dart — VIDUR Design Module
// Ambient screen presence for the blind navigator — Yantra-inspired sacred geometry

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vidur/theme/theme.dart';

class MandalaWidget extends StatefulWidget {
  final String state; // 'idle' | 'obstacle' | 'arrived'
  final double size;

  const MandalaWidget({super.key, required this.state, this.size = 300});

  @override
  State<MandalaWidget> createState() => _MandalaWidgetState();
}

class _MandalaWidgetState extends State<MandalaWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _arrivalController;
  late AnimationController _transitionController;

  String _currentState = 'idle';

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _arrivalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _applyState(widget.state);
  }

  @override
  void didUpdateWidget(MandalaWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _transitionController.forward(from: 0);
      setState(() => _currentState = widget.state);
      _applyState(widget.state);
    }
  }

  void _applyState(String state) {
    switch (state) {
      case 'idle':
        _rotationController.duration = const Duration(seconds: 20);
        _rotationController.repeat();
        _pulseController.stop();
        _arrivalController.reset();
        break;
      case 'obstacle':
        _rotationController.duration = const Duration(seconds: 5);
        _rotationController.repeat();
        _pulseController.duration = const Duration(milliseconds: 300);
        _pulseController.repeat(reverse: true);
        break;
      case 'arrived':
        _rotationController.stop();
        _pulseController.stop();
        _arrivalController.forward();
        break;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _arrivalController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationController,
          _pulseController,
          _arrivalController,
        ]),
        builder: (_, __) {
          double opacity = 1.0;
          if (_currentState == 'obstacle') {
            opacity = 0.4 + (_pulseController.value * 0.6);
          }

          return Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _MandalaPainter(
                  state: _currentState,
                  arrivalProgress: _arrivalController.value,
                ),
              ),
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms);
  }
}

class _MandalaPainter extends CustomPainter {
  final String state;
  final double arrivalProgress;

  _MandalaPainter({required this.state, required this.arrivalProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const gold = AppColors.navigateGold;

    if (state == 'arrived' && arrivalProgress > 0) {
      _paintArrival(canvas, center, gold);
      return;
    }

    // Outer circle — stroke, 30% opacity, radius 120
    _drawCircle(canvas, center, 120, gold.withOpacity(0.30), stroke: true);
    // Middle circle — stroke, 60% opacity, radius 80
    _drawCircle(canvas, center, 80, gold.withOpacity(0.60), stroke: true);
    // Inner circle — fill, 20% opacity, radius 40
    _drawCircle(canvas, center, 40, gold.withOpacity(0.20), stroke: false);

    // 8 radial lines from center to outer ring
    final linePaint = Paint()
      ..color = gold.withOpacity(0.40)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final end = Offset(
        center.dx + 120 * math.cos(angle),
        center.dy + 120 * math.sin(angle),
      );
      canvas.drawLine(center, end, linePaint);

      // 8 small dots at intersections with middle ring
      final dotCenter = Offset(
        center.dx + 80 * math.cos(angle),
        center.dy + 80 * math.sin(angle),
      );
      final dotPaint = Paint()
        ..color = gold.withOpacity(0.70)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, 3.5, dotPaint);
    }
  }

  void _paintArrival(Canvas canvas, Offset center, Color gold) {
    final t = arrivalProgress;

    // Rings expand outward and fade out
    for (int i = 0; i < 3; i++) {
      final radii = [40.0, 80.0, 120.0];
      final expandedRadius = radii[i] * (1.0 + t * 0.6);
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      _drawCircle(canvas, center, expandedRadius, gold.withOpacity(opacity * 0.5), stroke: true);
    }

    // Center fills safeGreen
    final greenOpacity = t.clamp(0.0, 1.0);
    _drawCircle(
      canvas, center, 40,
      AppColors.safeGreen.withOpacity(greenOpacity),
      stroke: false,
    );
  }

  void _drawCircle(Canvas canvas, Offset center, double radius, Color color, {required bool stroke}) {
    final paint = Paint()
      ..color = color
      ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MandalaPainter old) =>
      old.state != state || old.arrivalProgress != arrivalProgress;
}
