import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math;

import '../components/orb_widget.dart';
import '../components/arrival_card_widget.dart';
import '../core/contracts.dart';
import 'session_repository_impl.dart';
import 'help_screen.dart';

final sessionUpdatesProvider = StreamProvider<SessionState>((ref) {
  return ref.watch(sessionRepositoryProvider).sessionUpdates;
});

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class WatchHomeScreen extends ConsumerStatefulWidget {
  final String pin;

  const WatchHomeScreen({
    super.key,
    required this.pin,
  });

  @override
  ConsumerState<WatchHomeScreen> createState() => _WatchHomeScreenState();
}

class _WatchHomeScreenState extends ConsumerState<WatchHomeScreen> {
  OrbState _localOrbState = OrbState.safe;
  DateTime _lastMovement = DateTime.now();
  Timer? _pausedTimer;
  Timer? _movementCheckTimer;
  bool _notificationSent = false;
  bool _showHangingObstacleWarning = false;
  StreamSubscription<DatabaseEvent>? _obstacleSub;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _startMovementCheckTimer();
    
    _obstacleSub = FirebaseDatabase.instance
        .ref('sessions/${widget.pin}/hangingObstacleTriggered')
        .onValue
        .listen((event) {
      final triggered = event.snapshot.value == true;
      if (triggered && !_showHangingObstacleWarning) {
        if (mounted) {
          setState(() => _showHangingObstacleWarning = true);
        }
        Future.delayed(const Duration(seconds: 11), () {
          if (mounted) setState(() => _showHangingObstacleWarning = false);
        });
      }
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: darwinSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void _startMovementCheckTimer() {
    _movementCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_localOrbState == OrbState.safe) {
        final elapsedTime = DateTime.now().difference(_lastMovement);
        if (elapsedTime > const Duration(minutes: 2)) {
          setState(() {
            _localOrbState = OrbState.paused;
          });
          _startPausedTimer();
        }
      }
    });
  }

  void _startPausedTimer() {
    _pausedTimer?.cancel();
    _notificationSent = false;
    _pausedTimer = Timer(const Duration(minutes: 2), () async {
      if (_localOrbState == OrbState.paused && !_notificationSent) {
        _notificationSent = true;
        await _sendPauseNotification();
      }
    });
  }

  Future<void> _sendPauseNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'watch_channel',
      'Watch Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Alert',
      'Your person has stopped moving',
      details,
    );
  }

  @override
  void dispose() {
    _movementCheckTimer?.cancel();
    _pausedTimer?.cancel();
    _obstacleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionUpdatesProvider);

    ref.listen<AsyncValue<SessionState>>(sessionUpdatesProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final state = next.value!;
        
        if (previous?.value?.position != state.position && state.position != null) {
          _lastMovement = DateTime.now();
        }

        if (state.orbState == OrbState.help) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen()));
        } else if (state.orbState == OrbState.arrived) {
          setState(() => _localOrbState = OrbState.arrived);
        } else if (state.orbState == OrbState.paused) {
          setState(() => _localOrbState = OrbState.paused);
          _startPausedTimer();
        } else if (state.orbState == OrbState.safe) {
          setState(() => _localOrbState = OrbState.safe);
          _pausedTimer?.cancel();
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: _buildTopSection(),
                  ),
                ),
                Expanded(
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: _IsometricMapPainter(),
                            ),
                            Center(
                              child: _buildDotIndicator(sessionAsync.value?.position),
                            ),
                            if (_showHangingObstacleWarning)
                              _buildHangingObstacleWarning(constraints.biggest),
                          ],
                        );
                      }
                    ),
                  ),
                ),
              ],
            ),
            
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Guardian Peek',
                  style: TextStyle(
                    color: Color(0xFFC8A850),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8A850).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC8A850)),
                  ),
                  child: Text(
                    _localOrbState.name.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFC8A850),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    
    if (_localOrbState == OrbState.arrived) {
      return const ArrivalCardWidget(stats: SessionStats(distanceMeters: 0, duration: Duration.zero, obstaclesAvoided: 0));
    }
    return OrbWidget(state: _localOrbState);
  }

  Widget _buildDotIndicator(VidurPosition? position) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFC8A850),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds)
     .then()
     .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 1.seconds);
  }

  Widget _buildHangingObstacleWarning(Size size) {
    const double wx = 30.0;
    const double wy = 15.0;
    
    const double rad = 45 * 3.14159 / 180;
    final double rx = wx * math.cos(rad) - wy * math.sin(rad);
    final double ry = wx * math.sin(rad) + wy * math.cos(rad);
    final double sx = rx;
    final double sy = ry * 0.5;
    
    final dx = size.width / 2 + sx;
    final dy = size.height / 2 + sy;

    return Positioned(
      key: const ValueKey('waypoint_hanging_001'),
      left: dx - 40,
      top: dy - 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFE8A020), size: 24),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C0E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE8A020)),
            ),
            child: const Text(
              'Head height',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFFE8A020),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ).animate()
       .fadeIn(duration: 300.ms)
       .fadeOut(delay: 10.seconds, duration: 300.ms),
    );
  }
}

class _IsometricMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8A850).withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(1.0, 0.5);
    canvas.rotate(45 * 3.14159 / 180);

    const double step = 20.0;
    for (int i = -10; i <= 10; i++) {
        canvas.drawLine(
          Offset(i * step, -300),
          Offset(i * step, 300),
          paint,
        );
        canvas.drawLine(
          Offset(-300, i * step),
          Offset(300, i * step),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
