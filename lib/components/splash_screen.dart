// lib/components/splash_screen.dart — VIDUR Design Module
// 2.5s branded splash with shimmer-draw animation for "VIDUR" wordmark

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vidur/theme/theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeOutController;

  @override
  void initState() {
    super.initState();

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // After 2.5s, fade out then call onComplete
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _fadeOutController.forward().then((_) {
        if (mounted) widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeOutController,
      builder: (_, child) => Opacity(
        opacity: 1.0 - _fadeOutController.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "VIDUR" wordmark — shimmer draw + fade in
              Text(
                'VIDUR',
                style: GoogleFonts.cormorantGaramond(
                  fontWeight: FontWeight.w600,
                  fontSize: 64,
                  color: AppColors.navigateGold,
                  letterSpacing: 12,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .shimmer(
                    duration: 1500.ms,
                    color: AppColors.navigateGold.withOpacity(0.85),
                    angle: 0.3,
                  ),

              const SizedBox(height: AppSpacing.paddingM),

              // Tagline fades in at 1.8s
              Text(
                'The wisest guide in your pocket.',
                style: GoogleFonts.cormorantGaramond(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              )
                  .animate(delay: 1800.ms)
                  .fadeIn(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
