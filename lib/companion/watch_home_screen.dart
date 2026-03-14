import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math;

import '../components/orb_widget.dart';
import '../components/arrival_card_widget.dart';
import '../core/contracts.dart';
import 'session_repository_impl.dart';
import 'help_screen.dart';
import 'guardian_peek_overlay.dart';

final sessionUpdatesProvider = StreamProvider<SessionState>((ref) {
  return ref.watch(sessionRepositoryProvider).sessionUpdates;
});

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
  VenueMap? _venueMap;

  @override
  void initState() {
    super.initState();
    _startMovementCheckTimer();
    _loadVenueMap();
    
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

  Future<void> _loadVenueMap() async {
    try {
      final jsonString = await rootBundle.loadString('assets/venue/test_venue.json');
      final data = jsonDecode(jsonString);
      
      final waypoints = (data['waypoints'] as List).map((w) => Waypoint(
        id: w['id'],
        x: (w['x'] as num).toDouble(),
        y: (w['y'] as num).toDouble(),
        floor: w['floor'] as int,
        label: w['label'] as String?,
        isHangingObstacle: w['isHangingObstacle'] == true,
      )).toList();

      final edges = (data['edges'] as List).map((e) => WaypointEdge(
        fromId: e['fromId'],
        toId: e['toId'],
        distanceMeters: (e['distanceMeters'] as num).toDouble(),
      )).toList();

      if (mounted) {
        setState(() {
          _venueMap = VenueMap(venueId: data['venueId'], waypoints: waypoints, edges: edges);
        });
      }
    } catch (e) {
      debugPrint('Error loading venue map: $e');
    }
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
    // TODO: use Firebase Messaging instead
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

        if (state.peekState != null && state.peekState!.active && state.peekState!.agoraChannel != null) {
          // If a peek was requested and we're not already showing it, jump in
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute != 'peek_overlay') {
            Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'peek_overlay'),
                builder: (_) => GuardianPeekOverlay(
                  channelId: state.peekState!.agoraChannel!,
                  onClose: () {
                    if (mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            );
          }
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
                              painter: _IsometricMapPainter(venueMap: _venueMap),
                            ),
                            if (sessionAsync.value?.position != null && _venueMap != null)
                              Builder(
                                builder: (context) {
                                  final pos = sessionAsync.value!.position!;
                                  double minX = 0, minY = 0, maxX = 0, maxY = 0;
                                  minX = maxX = _venueMap!.waypoints.first.x;
                                  minY = maxY = _venueMap!.waypoints.first.y;
                                  for (final w in _venueMap!.waypoints) {
                                    if (w.x < minX) minX = w.x;
                                    if (w.x > maxX) maxX = w.x;
                                    if (w.y < minY) minY = w.y;
                                    if (w.y > maxY) maxY = w.y;
                                  }
                                  final cx = (minX + maxX) / 2;
                                  final cy = (minY + maxY) / 2;

                                  const double scale = 12.0;

                                  // Apply the same isometric transformation used in the painter
                                  // 1. Center the map coordinate
                                  final double mx = (pos.x - cx) * scale;
                                  final double my = (pos.y - cy) * scale;

                                  // 2. Rotate 45 degrees (pi/4)
                                  const double rad = 45 * math.pi / 180;
                                  final double rx = mx * math.cos(rad) - my * math.sin(rad);
                                  final double ry = mx * math.sin(rad) + my * math.cos(rad);

                                  // 3. Scale Y by 0.6 (isometric squish)
                                  final double finalX = rx;
                                  final double finalY = ry * 0.6;

                                  // 4. Translate back to center of screen (+50 for Y offset)
                                  final double left = (constraints.maxWidth / 2) + finalX - 8; // -8 to center the 16x16 dot
                                  final double top = (constraints.maxHeight / 2) + 50 + finalY - 8;

                                  return Positioned(
                                    left: left,
                                    top: top,
                                    child: _buildDotIndicator(pos),
                                  );
                                }
                              ),
                            if (_showHangingObstacleWarning)
                              _buildHangingObstacleWarning(constraints.biggest, sessionAsync),
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
                onPressed: () {
                  ref.read(sessionRepositoryProvider).requestPeek(PeekRequester.companion);
                },
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
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .scale(
       begin: const Offset(0.8, 0.8),
       end: const Offset(1.2, 1.2),
       duration: 1.seconds,
       curve: Curves.easeInOut,
     );
  }

  Widget _buildHangingObstacleWarning(Size size, AsyncValue<SessionState> sessionAsync) {
    if (_venueMap == null || sessionAsync.value?.position == null) return const SizedBox();
    
    // Default fallback coordinates if we can't find it
    double wx = 30.0;
    double wy = 15.0;

    // Try tracking the actual navigator position during the warning
    final pos = sessionAsync.value!.position!;
    wx = pos.x;
    wy = pos.y;
    
    // Find center
    double minX = 0, minY = 0, maxX = 0, maxY = 0;
    minX = maxX = _venueMap!.waypoints.first.x;
    minY = maxY = _venueMap!.waypoints.first.y;
    for (final w in _venueMap!.waypoints) {
      if (w.x < minX) minX = w.x;
      if (w.x > maxX) maxX = w.x;
      if (w.y < minY) minY = w.y;
      if (w.y > maxY) maxY = w.y;
    }
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    const double scale = 12.0;

    final double mx = (wx - cx) * scale;
    final double my = (wy - cy) * scale;

    const double rad = 45 * math.pi / 180;
    final double rx = mx * math.cos(rad) - my * math.sin(rad);
    final double ry = mx * math.sin(rad) + my * math.cos(rad);

    final double finalX = rx;
    final double finalY = ry * 0.6;

    final double dx = (size.width / 2) + finalX;
    final double dy = (size.height / 2) + 50 + finalY;

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
  final VenueMap? venueMap;

  _IsometricMapPainter({this.venueMap});

  @override
  void paint(Canvas canvas, Size size) {
    if (venueMap == null) return;

    final paintLine = Paint()
      ..color = const Color(0xFFC8A850).withOpacity(0.3)
      ..strokeWidth = 2.0;

    final paintNode = Paint()
      ..color = const Color(0xFFC8A850).withOpacity(0.8)
      ..style = PaintingStyle.fill;
      
    final paintDest = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Center map and scale it up slightly since our coordinates are small (10-30 meters)
    canvas.translate(size.width / 2, size.height / 2 + 50);
    canvas.scale(1.0, 0.6); // Isometric squish
    canvas.rotate(45 * math.pi / 180);

    const double scale = 12.0; // scale meters to pixels

    // Find the center of our bounding box to center the draw
    double minX = 0, minY = 0, maxX = 0, maxY = 0;
    if (venueMap!.waypoints.isNotEmpty) {
      minX = maxX = venueMap!.waypoints.first.x;
      minY = maxY = venueMap!.waypoints.first.y;
      for (final w in venueMap!.waypoints) {
        if (w.x < minX) minX = w.x;
        if (w.x > maxX) maxX = w.x;
        if (w.y < minY) minY = w.y;
        if (w.y > maxY) maxY = w.y;
      }
    }
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    Offset getOffset(String id) {
      final w = venueMap!.waypoints.firstWhere((w) => w.id == id);
      return Offset((w.x - cx) * scale, (w.y - cy) * scale);
    }

    // Draw edges
    for (final edge in venueMap!.edges) {
      try {
        final p1 = getOffset(edge.fromId);
        final p2 = getOffset(edge.toId);
        canvas.drawLine(p1, p2, paintLine);
      } catch (_) {}
    }

    // Draw nodes
    for (final w in venueMap!.waypoints) {
      final p = Offset((w.x - cx) * scale, (w.y - cy) * scale);
      if (w.id == 'destination') {
        canvas.drawCircle(p, 6.0, paintDest);
      } else {
        canvas.drawCircle(p, 4.0, paintNode);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricMapPainter oldDelegate) {
    return oldDelegate.venueMap != venueMap;
  }
}
