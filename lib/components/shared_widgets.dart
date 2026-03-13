// lib/components/shared_widgets.dart — VIDUR Design Module
// Shared UI atoms: GoldButtonWidget, StatusPillWidget, PinCardWidget

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vidur/core/contracts.dart';
import 'package:vidur/theme/theme.dart';

// ─────────────────────────── GOLD BUTTON ───────────────────────────

class GoldButtonWidget extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isWatchMode;

  const GoldButtonWidget({
    super.key,
    required this.label,
    required this.onTap,
    this.isWatchMode = false,
  });

  @override
  State<GoldButtonWidget> createState() => _GoldButtonWidgetState();
}

class _GoldButtonWidgetState extends State<GoldButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isWatchMode ? AppColors.watchGold : AppColors.navigateGold;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.paddingM,
            horizontal: AppSpacing.paddingL * 1.33, // ~32px
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXL / 2), // 24px
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.buttonLabel.copyWith(
              color: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── STATUS PILL ───────────────────────────

class StatusPillWidget extends StatelessWidget {
  final String label;
  final OrbState status;

  const StatusPillWidget({super.key, required this.label, required this.status});

  Color get _dotColor {
    switch (status) {
      case OrbState.safe:
        return AppColors.safeGreen;
      case OrbState.paused:
        return AppColors.watchGold;
      case OrbState.help:
        return AppColors.alertRed;
      case OrbState.arrived:
        return AppColors.safeGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingM,
        vertical: AppSpacing.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── PIN CARD ───────────────────────────

class PinCardWidget extends StatelessWidget {
  final String pin;

  const PinCardWidget({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: const EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.navigateGold, width: 1.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your PIN', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.paddingS),
          Text(
            pin,
            style: AppTextStyles.pinDisplay.copyWith(letterSpacing: 12),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 300.ms);
  }
}
