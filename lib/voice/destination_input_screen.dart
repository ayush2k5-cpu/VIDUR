// lib/voice/destination_input_screen.dart
// Phase 1 — Voice destination entry screen for VIDUR Navigator

import 'package:flutter/material.dart';
// flutter_animate not needed — waveform uses AnimationController directly
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vidur/core/contracts.dart';
import 'package:vidur/theme/theme.dart';

class DestinationInputScreen extends StatefulWidget {
  final NavigationEngine engine;

  const DestinationInputScreen({super.key, required this.engine});

  @override
  State<DestinationInputScreen> createState() => _DestinationInputScreenState();
}

class _DestinationInputScreenState extends State<DestinationInputScreen> {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _recognizedText = '';
  bool _sttAvailable = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttAvailable = await _stt.initialize(
      onError: (_) => _stopListening(),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (_sttAvailable && mounted) _startListening();
  }

  Future<void> _startListening() async {
    if (!_sttAvailable || _isListening) return;
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });
    await _stt.listen(
      onResult: (result) {
        if (mounted) {
          setState(() => _recognizedText = result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _confirmDestination() async {
    if (_recognizedText.trim().isEmpty || _navigating) return;
    setState(() => _navigating = true);

    await _stopListening();

    // Use spoken text as destinationId (real engines can normalise downstream)
    final destinationId = _recognizedText.trim();

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(1.0);
    await _tts.speak('Got it. Navigating to $destinationId.');

    await widget.engine.setDestination(destinationId);
  }

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Screen title
            Text(
              'Where to?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 26,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Speak your destination',
              style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
            ),

            const Spacer(),

            // ── Waveform visualiser ──────────────────────────────────
            SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(5, (i) {
                  // Each bar has a staggered delay so they animate offset from each other
                  return _WaveBar(
                    isListening: _isListening,
                    delayMs: i * 80,
                  );
                }),
              ),
            ),

            const SizedBox(height: 40),

            // ── Recognised text ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _recognizedText.isNotEmpty
                    ? Text(
                        _recognizedText,
                        key: const ValueKey('recognized'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      )
                    : Text(
                        _isListening ? 'Listening…' : 'Tap mic to speak',
                        key: const ValueKey('placeholder'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const Spacer(),

            // ── Action row: mic toggle + Go button ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  // Mic toggle button
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening
                              ? AppColors.navigateGold
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        color: _isListening
                            ? AppColors.navigateGold.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_off,
                        color: _isListening
                            ? AppColors.navigateGold
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Go button
                  Expanded(
                    child: GestureDetector(
                      onTap: _recognizedText.isNotEmpty && !_navigating
                          ? _confirmDestination
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        decoration: BoxDecoration(
                          color: _recognizedText.isNotEmpty && !_navigating
                              ? AppColors.navigateGold
                              : AppColors.navigateGold.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _navigating ? 'On my way…' : 'GO',
                          style: AppTextStyles.buttonLabel.copyWith(
                            color: _recognizedText.isNotEmpty && !_navigating
                                ? AppColors.background
                                : AppColors.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ─── Animated waveform bar ──────────────────────────────────────────────────
class _WaveBar extends StatefulWidget {
  final bool isListening;
  final int delayMs;

  const _WaveBar({required this.isListening, required this.delayMs});

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _height;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 380 + widget.delayMs),
    );
    _height = Tween<double>(begin: 8, end: 48).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isListening) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void didUpdateWidget(_WaveBar old) {
    super.didUpdateWidget(old);
    if (widget.isListening != old.isListening) {
      if (widget.isListening) {
        Future.delayed(Duration(milliseconds: widget.delayMs), () {
          if (mounted) _ctrl.repeat(reverse: true);
        });
      } else {
        _ctrl.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedBuilder(
        animation: _height,
        builder: (_, __) => Container(
          width: 5,
          height: _height.value,
          decoration: BoxDecoration(
            color: AppColors.navigateGold,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

