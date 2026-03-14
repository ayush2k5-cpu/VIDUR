// lib/voice/audio_service.dart
// Phase 2 — Unified audio engine for VIDUR Navigator
// Handles TTS voice, binaural spatial tones, and haptic warnings.
// Imports NOTHING from other lib/ subfolders.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _tonePlayer = AudioPlayer();

  AudioService() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
  }

  // ─── Voice Output ───────────────────────────────────────────────────────────

  Future<void> speak(String text, {double rate = 0.45}) async {
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  Future<void> speakSlow(String text) => speak(text, rate: 0.35);

  // ─── Binaural Spatial Audio ─────────────────────────────────────────────────
  //
  // Generates a stereo 16-bit PCM WAV in memory with independent per-channel
  // amplitudes, writes it to the app's temp directory, and plays it via
  // just_audio. This is the only reliable way to get true L/R channel
  // separation on Android without additional native code.
  //
  // bearingDegrees:  0 = straight (equal), -90 = full left, +90 = full right

  Future<void> playBinaural(double bearingDegrees) async {
    final pan      = (bearingDegrees.clamp(-90.0, 90.0) + 90.0) / 180.0;
    final panAngle = pan * math.pi / 2.0;
    final leftVol  = math.cos(panAngle);
    final rightVol = math.sin(panAngle);

    try {
      await _tonePlayer.stop();
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/binaural_tone.wav');
      await file.writeAsBytes(
        _buildWav(leftVol: leftVol, rightVol: rightVol),
      );
      await _tonePlayer.setAudioSource(AudioSource.uri(Uri.file(file.path)));
      await _tonePlayer.play();
    } catch (e) {
      debugPrint('Binaural error: $e');
    }
  }

  // ─── Hazard Warnings ────────────────────────────────────────────────────────

  Future<void> playObstacleWarning() async {
    HapticFeedback.mediumImpact();
    await speak('Obstacle ahead, slow down');
  }

  Future<void> playHangingObstacleWarning() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    HapticFeedback.heavyImpact();
    await speak('Caution. Hanging obstacle at head height. Duck slightly and proceed.');
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _tts.stop();
    await _tonePlayer.dispose();
  }
}

// ─── Stereo WAV builder ──────────────────────────────────────────────────────
//
// 44100 Hz, 16-bit, stereo, 1.5 seconds, 750 Hz sine wave.
// leftVol / rightVol are independent [0.0, 1.0] amplitudes per channel.
// 20% fade-out prevents audible clicks at the end.

Uint8List _buildWav({
  required double leftVol,
  required double rightVol,
  double frequency = 750.0,
  double durationSeconds = 1.5,
}) {
  const sampleRate    = 44100;
  const numChannels   = 2;
  const bitsPerSample = 16;
  final  numSamples   = (sampleRate * durationSeconds).round();
  final  dataSize     = numSamples * numChannels * (bitsPerSample ~/ 8);

  final buf = ByteData(44 + dataSize);
  int o = 0;

  void ascii(String s) { for (final c in s.codeUnits) buf.setUint8(o++, c); }
  void u32(int v) { buf.setUint32(o, v, Endian.little); o += 4; }
  void u16(int v) { buf.setUint16(o, v, Endian.little); o += 2; }
  void i16(int v) { buf.setInt16(o,  v, Endian.little); o += 2; }

  ascii('RIFF'); u32(36 + dataSize); ascii('WAVE');
  ascii('fmt '); u32(16); u16(1); u16(numChannels);
  u32(sampleRate);
  u32(sampleRate * numChannels * (bitsPerSample ~/ 8));
  u16(numChannels * (bitsPerSample ~/ 8));
  u16(bitsPerSample);
  ascii('data'); u32(dataSize);

  final fadeStart = (numSamples * 0.8).round();
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // Generate a percussive harmonic "ping" instead of a flat sine wave:
    // Fundamental + Octave + Harmonic overtone
    final f1 = math.sin(2 * math.pi * frequency * t);
    final f2 = math.sin(2 * math.pi * (frequency * 2.0) * t) * 0.5;
    final f3 = math.sin(2 * math.pi * (frequency * 3.0) * t) * 0.25;

    // Use a very gentle amplitude wobble instead of a sharp decay
    // This allows the full 1.5s tone to survive Android TTS audio ducking!
    final lfo = 0.8 + 0.2 * math.sin(2 * math.pi * 4.0 * t);

    // Combine them, scale to fit roughly in [-1, 1] range
    final raw = (f1 + f2 + f3) * lfo * 0.5;

    final fade = i < fadeStart ? 1.0 : (numSamples - i) / (numSamples - fadeStart);
    i16((raw * leftVol  * fade * 32767).round().clamp(-32768, 32767));
    i16((raw * rightVol * fade * 32767).round().clamp(-32768, 32767));
  }

  return buf.buffer.asUint8List();
}
