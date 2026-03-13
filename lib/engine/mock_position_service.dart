// lib/engine/mock_position_service.dart — Person 1 owns this file.
// Temporary. FusedPositionService replaces at venue. Zero changes to consumers.

import 'dart:async';
import '../core/contracts.dart';

class MockPositionService implements PositionStream {
  static const _loop = [
    VidurPosition(x: 10.0, y: 5.0,  floor: 0, confidence: 0.9),
    VidurPosition(x: 20.0, y: 5.0,  floor: 0, confidence: 0.9),
    VidurPosition(x: 30.0, y: 5.0,  floor: 0, confidence: 0.9),
    // index 3 — simulates user reaching the hanging obstacle waypoint
    VidurPosition(x: 30.0, y: 15.0, floor: 0, confidence: 0.9,
        waypointId: 'waypoint_hanging_001'),
    VidurPosition(x: 20.0, y: 15.0, floor: 0, confidence: 0.9),
    VidurPosition(x: 10.0, y: 15.0, floor: 0, confidence: 0.9),
  ];

  int _index = 0;
  StreamController<VidurPosition>? _controller;
  Timer? _timer;

  @override
  Stream<VidurPosition> get positionUpdates {
    _controller ??= StreamController<VidurPosition>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> initialize(VenueMap venue) async {
    _controller ??= StreamController<VidurPosition>.broadcast();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _controller!.add(_loop[_index % _loop.length]);
      _index++;
    });
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _controller?.close();
  }
}
