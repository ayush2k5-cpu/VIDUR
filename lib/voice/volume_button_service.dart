// lib/voice/volume_button_service.dart
// Phase 2 — Hardware volume-button gesture detector for VIDUR Navigator
//
// Maps volume key presses to navigation actions:
//   Vol-Up  short (<1.5s)  → onRepeatInstruction  (1 soft haptic)
//   Vol-Up  hold  (≥1.5s)  → onNavigatorPeekRequest (2 medium haptics + voice)
//   Vol-Down short (<2.0s) → onSlowRepeat           (1 soft haptic)
//   Vol-Down hold  (≥2.0s) → onHelpFired            (3 heavy haptics + voice)
//
// All callbacks are injected — nothing is hardcoded.
// Call dispose() when the owning widget unmounts.

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';


class VolumeButtonService {
  // ── Injected callbacks ───────────────────────────────────────────────────────
  final VoidCallback onRepeatInstruction;
  final VoidCallback onNavigatorPeekRequest;
  final VoidCallback onSlowRepeat;
  final VoidCallback onHelpFired;

  // ── Internal state ───────────────────────────────────────────────────────────
  final Stopwatch _stopwatch = Stopwatch();
  LogicalKeyboardKey? _heldKey;
  final FlutterTts _tts = FlutterTts();

  VolumeButtonService({
    required this.onRepeatInstruction,
    required this.onNavigatorPeekRequest,
    required this.onSlowRepeat,
    required this.onHelpFired,
  }) {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(1.0);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  bool _handleKey(KeyEvent event) {
    final key = event.logicalKey;

    final isVolumeKey = key == LogicalKeyboardKey.audioVolumeUp ||
        key == LogicalKeyboardKey.audioVolumeDown;

    if (!isVolumeKey) return false; // pass through non-volume keys

    if (event is KeyDownEvent) {
      _heldKey = key;
      _stopwatch
        ..reset()
        ..start();
      return true; // consume the event
    }

    if (event is KeyUpEvent && _heldKey == key) {
      _stopwatch.stop();
      final elapsed = _stopwatch.elapsedMilliseconds;
      _heldKey = null;

      if (key == LogicalKeyboardKey.audioVolumeUp) {
        if (elapsed < 1500) {
          _shortVolUp();
        } else {
          _holdVolUp();
        }
      } else {
        // audioVolumeDown
        if (elapsed < 2000) {
          _shortVolDown();
        } else {
          _holdVolDown();
        }
      }
      return true;
    }

    return false;
  }

  // ── Volume Up: short press ────────────────────────────────────────────────────
  void _shortVolUp() {
    HapticFeedback.lightImpact();
    onRepeatInstruction();
  }

  // ── Volume Up: hold ──────────────────────────────────────────────────────────
  Future<void> _holdVolUp() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 160));
    HapticFeedback.mediumImpact();
    await _tts.speak('Requesting video connection');
    onNavigatorPeekRequest();
  }

  // ── Volume Down: short press ──────────────────────────────────────────────────
  void _shortVolDown() {
    HapticFeedback.lightImpact();
    onSlowRepeat();
  }

  // ── Volume Down: hold ─────────────────────────────────────────────────────────
  Future<void> _holdVolDown() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 160));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 160));
    HapticFeedback.heavyImpact();
    await _tts.speak('Help alert sent to your companion');
    onHelpFired();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _tts.stop();
    _stopwatch.reset();
  }
}
