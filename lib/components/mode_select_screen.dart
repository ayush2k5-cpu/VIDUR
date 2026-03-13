// lib/components/mode_select_screen.dart — VIDUR Design Module
// First screen after splash — two-panel layout with Hero expansion

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vidur/theme/theme.dart';

class ModeSelectScreen extends StatefulWidget {
  final VoidCallback onNavigatorSelected;
  final VoidCallback onCompanionSelected;

  const ModeSelectScreen({
    super.key,
    required this.onNavigatorSelected,
    required this.onCompanionSelected,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  bool _leftExpanding = false;
  bool _rightExpanding = false;

  void _onNavigatorTap() {
    setState(() => _leftExpanding = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onNavigatorSelected();
    });
  }

  void _onCompanionTap() {
    setState(() => _rightExpanding = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onCompanionSelected();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Row(
          children: [
            // LEFT PANEL — Navigator
            Expanded(
              flex: _leftExpanding ? 10 : (_rightExpanding ? 0 : 1),
              child: GestureDetector(
                onTap: _onNavigatorTap,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background,
                        AppColors.navigatorPanelDark,
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle mandala ring
                      CustomPaint(
                        size: Size(size.width * 0.5, size.width * 0.5),
                        painter: _SubtleRingPainter(AppColors.navigateGold),
                      ),
                      // Text content
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.paddingL),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'I need guidance',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.screenTitle.copyWith(
                                color: AppColors.navigateGold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.paddingS),
                            Text(
                              'For the navigator',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms),
            ),

            // Divider
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: (_leftExpanding || _rightExpanding) ? 0 : 1,
              color: AppColors.border,
            ),

            // RIGHT PANEL — Companion
            Expanded(
              flex: _rightExpanding ? 10 : (_leftExpanding ? 0 : 1),
              child: GestureDetector(
                onTap: _onCompanionTap,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background,
                        AppColors.companionPanelDark,
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle orb glow
                      Container(
                        width: size.width * 0.4,
                        height: size.width * 0.4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.watchGold.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Text content
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.paddingL),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "I'm watching\nover someone",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.screenTitle.copyWith(
                                color: AppColors.watchGold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.paddingS),
                            Text(
                              'For the companion',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single subtle ring for the navigator panel background
class _SubtleRingPainter extends CustomPainter {
  final Color baseColor;

  _SubtleRingPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final radius in [size.width * 0.3, size.width * 0.42, size.width * 0.48]) {
      canvas.drawCircle(center, radius, paint);
    }

    // 8 radial lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      canvas.drawLine(
        center,
        Offset(
          center.dx + size.width * 0.48 * math.cos(angle),
          center.dy + size.width * 0.48 * math.sin(angle),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SubtleRingPainter old) => false;
}
