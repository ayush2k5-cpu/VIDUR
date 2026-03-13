// lib/components/arrival_card_widget.dart — VIDUR Design Module
// Full-screen emotional climax shown when navigator arrives safely

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vidur/core/contracts.dart';
import 'package:vidur/theme/theme.dart';

class ArrivalCardWidget extends StatefulWidget {
  final SessionStats stats;
  final VoidCallback? onClose;

  const ArrivalCardWidget({super.key, required this.stats, this.onClose});

  @override
  State<ArrivalCardWidget> createState() => _ArrivalCardWidgetState();
}

class _ArrivalCardWidgetState extends State<ArrivalCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _countController;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward(from: 0);
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Aurora gradient (top 30%)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.safeGreen.withValues(alpha: 0.18),
                    AppColors.navigateGold.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 1000.ms),
          ),

          // Main content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Checkmark
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.safeGreen,
                  size: 96,
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 100.ms,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(1, 1),
                      duration: 150.ms,
                    ),

                const SizedBox(height: AppSpacing.paddingM),

                // "Arrived Safely"
                Text(
                  'Arrived Safely',
                  style: AppTextStyles.screenTitle,
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 400.ms),

                const Spacer(flex: 1),

                // Stats row
                AnimatedBuilder(
                  animation: _countController,
                  builder: (_, __) {
                    final t = _countController.value;
                    final dist = (stats.distanceMeters * t).toStringAsFixed(0);
                    final dur = Duration(
                      seconds: (stats.duration.inSeconds * t).round(),
                    );
                    final obs = (stats.obstaclesAvoided * t).round();

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingL),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatColumn(value: '${dist}m', label: 'Distance'),
                          _StatColumn(
                              value: _formatDuration(dur), label: 'Duration'),
                          _StatColumn(
                              value: '$obs', label: 'Obstacles\navoided'),
                        ],
                      ),
                    );
                  },
                )
                    .animate(delay: 1500.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.15, duration: 400.ms),

                const Spacer(flex: 1),

                // Tagline
                Text(
                  '"The wisest guide in your pocket."',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: AppColors.watchGold,
                    fontStyle: FontStyle.italic,
                  ),
                )
                    .animate(delay: 2500.ms)
                    .fadeIn(duration: 500.ms),

                const Spacer(flex: 1),

                // Close button
                GestureDetector(
                  onTap: widget.onClose,
                  child: Text('Close', style: AppTextStyles.caption),
                )
                    .animate(delay: 4000.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: AppSpacing.paddingXL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.statusText.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
