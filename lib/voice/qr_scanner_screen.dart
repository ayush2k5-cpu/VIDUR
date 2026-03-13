// lib/voice/qr_scanner_screen.dart
// Phase 1 — QR Scanner Entry Screen for VIDUR Navigator

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vidur/core/contracts.dart';
import 'package:vidur/core/providers.dart';
import 'package:vidur/theme/theme.dart';
import 'package:vidur/voice/destination_input_screen.dart';
import 'package:vidur/voice/providers.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final FlutterTts _tts = FlutterTts();

  bool _scanned = false;
  String? _pin;

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return; // not our QR format — ignore
    }

    final venueId = payload['venueId'] as String?;
    if (venueId == null) return;

    _scanned = true;
    await _controller.stop();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Create session → get PIN
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final String pin;
    try {
      pin = await sessionRepo.createSession(venueId);
    } catch (e) {
      // Reset so user can retry
      _scanned = false;
      _controller.start();
      return;
    }

    setState(() => _pin = pin);

    // Persist PIN into shared provider so NavigateMainScreen can write Firebase events
    ref.read(currentSessionPinProvider.notifier).state = pin;

    // Speak the session start message
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(1.0);
    await _tts.speak('Session started. PIN is ${pin.split('').join(', ')}. Where would you like to go?');

    // Show PIN for 3 seconds, then navigate
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final engineAsync = ref.read(navigationEngineProvider);
    final NavigationEngine engine = engineAsync.maybeWhen(
      data: (e) => e,
      orElse: () => throw StateError('NavigationEngine not ready'),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DestinationInputScreen(engine: engine),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onQrDetected,
          ),

          // Dark vignette overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),

          // Gold corner brackets
          const _CornerBrackets(),

          // Scan prompt label
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _pin == null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Point at venue QR code',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),

          // PIN overlay — shown for 3 s after scan
          if (_pin != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                  border: Border.all(color: AppColors.navigateGold.withOpacity(0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SESSION PIN',
                      style: AppTextStyles.caption.copyWith(
                        letterSpacing: 3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pin!,
                      style: AppTextStyles.pinDisplay,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gold L-shaped corner brackets forming the scan frame.
class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: CustomPaint(painter: _BracketPainter()),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navigateGold
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const len = 28.0; // arm length of each bracket

    // Top-left
    canvas.drawLine(const Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => false;
}
