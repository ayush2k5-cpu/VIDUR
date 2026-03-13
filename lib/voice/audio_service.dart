// lib/voice/audio_service.dart
// Phase 2 — Unified audio engine for VIDUR Navigator
// Handles TTS voice, binaural spatial tones, and haptic warnings.
// Imports NOTHING from other lib/ subfolders.

import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();

  AudioService() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(1.0);
    _tts.setVolume(1.0);
  }

  // ─── Voice Output ───────────────────────────────────────────────────────────

  /// Speaks [text] at normal or custom [rate].
  Future<void> speak(String text, {double rate = 1.0}) async {
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  /// Speaks [text] at 0.75× rate — for users who need more time to process.
  Future<void> speakSlow(String text) => speak(text, rate: 0.75);

  // ─── Binaural Spatial Audio ─────────────────────────────────────────────────

  /// Plays a directional tone to indicate bearing relative to forward.
  ///
  /// [bearingDegrees]:
  ///   0   = straight ahead (equal L/R volume)
  ///   -90 = full left
  ///   +90 = full right
  ///
  /// Constant-power pan law:
  ///   panAngle = bearing mapped to [0°, 90°] from centre-left to centre-right
  ///   leftVol  = cos(panAngle * π/2)
  ///   rightVol = sin(panAngle * π/2)
  final AudioPlayer _leftPlayer  = AudioPlayer();
  final AudioPlayer _rightPlayer = AudioPlayer();

  Future<void> playBinaural(double bearingDegrees) async {
    // Normalise bearing to [0, 1] where 0 = full-left, 0.5 = centre, 1 = full-right
    final pan = ((bearingDegrees.clamp(-90.0, 90.0) + 90.0) / 180.0);
    // Constant-power pan (equal-power crossfade)
    final panAngle = pan * math.pi / 2.0;
    final leftVol  = math.cos(panAngle);  // 1.0 at far-left, 0.0 at far-right
    final rightVol = math.sin(panAngle);  // 0.0 at far-left, 1.0 at far-right

    const asset = 'assets/sounds/tone_750hz.mp3';
    try {
      await Future.wait([
        _leftPlayer.stop(),
        _rightPlayer.stop(),
      ]);
      await Future.wait([
        _leftPlayer.setAudioSource(AudioSource.asset(asset)),
        _rightPlayer.setAudioSource(AudioSource.asset(asset)),
      ]);
      await _leftPlayer.setVolume(leftVol * 0.55);
      await _rightPlayer.setVolume(rightVol * 0.55);
      _leftPlayer.play();
      _rightPlayer.play();
    } catch (_) {
      // Asset may not exist in dev — silently skip
    }
  }

  // ─── Hazard Warnings ────────────────────────────────────────────────────────

  /// Ground-level obstacle: 1 haptic pulse + voice warning.
  Future<void> playObstacleWarning() async {
    HapticFeedback.mediumImpact();
    await speak('Obstacle ahead, slow down');
  }

  /// Hanging obstacle at head height: 2 sharp haptics + detailed voice warning.
  Future<void> playHangingObstacleWarning() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    HapticFeedback.heavyImpact();
    await speak('Caution. Hanging obstacle at head height. Duck slightly and proceed.');
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _tts.stop();
    await Future.wait([_leftPlayer.dispose(), _rightPlayer.dispose()]);
  }
}
