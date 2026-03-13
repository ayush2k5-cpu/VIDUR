// lib/navigate/navigate_main_screen.dart
// Phase 3 — Primary navigation screen for the VIDUR blind navigator.
//
// Layout:
//   ┌─────────────────────────────┐
//   │  [top pill] distance / ETA  │
//   │                             │
//   │      MandalaWidget          │
//   │                             │
//   │  [bottom 30%] instruction   │
//   └─────────────────────────────┘
//
// Volume buttons are intercepted by VolumeButtonService.
// NavigationEngine.instructions stream drives all audio + visual state.

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vidur/components/mandala_widget.dart';
import 'package:vidur/core/constants.dart';
import 'package:vidur/core/contracts.dart';
import 'package:vidur/core/providers.dart';
import 'package:vidur/theme/theme.dart';
import 'package:vidur/voice/audio_service.dart';
import 'package:vidur/voice/providers.dart' as voice_providers;
import 'package:vidur/voice/navigation_foreground_service.dart';
import 'package:vidur/voice/volume_button_service.dart';

class NavigateMainScreen extends ConsumerStatefulWidget {
  const NavigateMainScreen({super.key});

  @override
  ConsumerState<NavigateMainScreen> createState() => _NavigateMainScreenState();
}

class _NavigateMainScreenState extends ConsumerState<NavigateMainScreen> {
  // ── Services ──────────────────────────────────────────────────────────────────
  final AudioService _audio = AudioService();
  VolumeButtonService? _volumeService;

  // ── State ─────────────────────────────────────────────────────────────────────
  String _mandalaState = 'idle';
  String _instructionText = 'Initialising guidance…';
  double _distanceMeters = 0;
  NavigationInstruction? _lastInstruction;

  // ── Hanging obstacle guard ────────────────────────────────────────────────────
  bool _hangingObstacleFired = false;

  // ── Stream subscriptions ──────────────────────────────────────────────────────
  StreamSubscription<NavigationInstruction>? _instructionSub;
  StreamSubscription<VidurPosition>? _positionSub;

  // ── Session PIN (needed for Firebase write in Phase 4) ────────────────────────
  String? _sessionPin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Capture the session PIN from the shared provider (set by QrScannerScreen)
    _sessionPin = ref.read(voice_providers.currentSessionPinProvider);

    // Wire VolumeButtonService with all four callbacks
    final sessionRepo = ref.read(voice_providers.sessionRepositoryProvider);

    _volumeService = VolumeButtonService(
      onRepeatInstruction: _repeatInstruction,
      onSlowRepeat: _slowRepeatInstruction,
      onHelpFired: () => sessionRepo.fireHelp(),
      onNavigatorPeekRequest: () =>
          sessionRepo.requestPeek(PeekRequester.navigator),
    );

    // Subscribe to position stream for hanging obstacle detection (Phase 4)
    final posStream = await ref.read(positionStreamProvider.future);
    _positionSub = posStream.positionUpdates.listen(_onPositionUpdate);

    // Subscribe to navigation instructions
    final engine = await ref.read(navigationEngineProvider.future);
    _instructionSub = engine.instructions.listen(_onInstruction);

    // Phase 5 — keep navigation alive when backgrounded
    await NavigationForegroundService.startService();
  }

  // ── Instruction handler ───────────────────────────────────────────────────────
  Future<void> _onInstruction(NavigationInstruction instruction) async {
    _lastInstruction = instruction;

    // Derive mandala state from instruction type
    final newMandalaState = switch (instruction.type) {
      InstructionType.obstacle => 'obstacle',
      InstructionType.arrived  => 'arrived',
      _                        => 'idle',
    };

    if (mounted) {
      setState(() {
        _instructionText = instruction.spokenText;
        _distanceMeters  = instruction.distanceMeters;
        _mandalaState    = newMandalaState;
      });
    }

    // Audio — speak + spatial tone; keep foreground service notification in sync
    NavigationForegroundService.updateInstruction(instruction.spokenText);
    await _audio.speak(instruction.spokenText);
    await _audio.playBinaural(instruction.bearingDegrees);

    // Handle arrival
    if (instruction.type == InstructionType.arrived) {
      _onArrived();
    }
  }

  // ── Position handler (hanging obstacle — Phase 4 logic wired here) ────────────
  void _onPositionUpdate(VidurPosition position) {
    if (_hangingObstacleFired) return;
    if (position.waypointId == kHangingObstacleWaypointId) {
      _hangingObstacleFired = true;
      _fireHangingObstacle();
    }
  }

  Future<void> _fireHangingObstacle() async {
    await _audio.playHangingObstacleWarning();

    // Write to Firebase — requires PIN from session stream
    if (_sessionPin != null) {
      await FirebaseDatabase.instance
          .ref('sessions/$_sessionPin/hangingObstacleTriggered')
          .set(true);
    }
  }

  // ── Arrival ──────────────────────────────────────────────────────────────────
  Future<void> _onArrived() async {
    // Play arrival chime via TTS (asset chime can replace later)
    await _audio.speak('You have arrived at your destination.');

    // Build basic stats (engine doesn't expose these directly — use defaults)
    final stats = SessionStats(
      distanceMeters: _distanceMeters,
      duration: Duration.zero,
      obstaclesAvoided: 0,
    );
    try {
      final sessionRepo = ref.read(voice_providers.sessionRepositoryProvider);
      await sessionRepo.fireArrival(stats);
    } catch (_) {
      // silently skip if repo not wired
    }
  }

  // ── Volume button callbacks ───────────────────────────────────────────────────
  void _repeatInstruction() {
    HapticFeedback.lightImpact();
    if (_lastInstruction != null) {
      _audio.speak(_lastInstruction!.spokenText);
    }
  }

  void _slowRepeatInstruction() {
    HapticFeedback.lightImpact();
    if (_lastInstruction != null) {
      _audio.speakSlow(_lastInstruction!.spokenText);
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _volumeService?.dispose();
    _instructionSub?.cancel();
    _positionSub?.cancel();
    _audio.dispose();
    NavigationForegroundService.stopService();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Top status pill ──────────────────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _DistancePill(meters: _distanceMeters),
              ),
            ),
          ),

          // ── Mandala — dead centre ────────────────────────────────────────────
          Center(
            child: MandalaWidget(state: _mandalaState, size: 280),
          ),

          // ── Bottom instruction panel — bottom 30% ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.30,
            child: _InstructionPanel(text: _instructionText),
          ),
        ],
      ),
    );
  }
}

// ─── Distance pill ────────────────────────────────────────────────────────────
class _DistancePill extends StatelessWidget {
  final double meters;

  const _DistancePill({required this.meters});

  String get _label {
    if (meters <= 0) return 'Calculating…';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        border: Border.all(
          color: AppColors.navigateGold.withOpacity(0.35),
        ),
      ),
      child: Text(
        _label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.navigateGold,
        ),
      ),
    );
  }
}

// ─── Instruction panel ────────────────────────────────────────────────────────
class _InstructionPanel extends StatelessWidget {
  final String text;

  const _InstructionPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            AppColors.background.withOpacity(0.92),
            AppColors.background.withOpacity(0.0),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            text,
            key: ValueKey(text),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
