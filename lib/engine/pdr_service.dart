// lib/engine/pdr_service.dart — Person 1 owns this file.

import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants.dart';
import '../core/contracts.dart';

class PdrService implements PositionStream {
  static const _stepLengthMeters = 0.75;
  static const _stepThreshold = 11.0;   // m/s² peak detection
  static const _stepHysteresis = 9.0;   // m/s² reset threshold

  double _x = 0, _y = 0;
  int _floor = 0;
  double _bearingDegrees = 0;
  double _confidence = 1.0;
  bool _peakDetected = false;

  final _controller = StreamController<VidurPosition>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  Stream<VidurPosition> get positionUpdates => _controller.stream;

  @override
  Future<void> initialize(VenueMap venue) async {
    _accelSub = accelerometerEventStream().listen(_onAccel);
  }

  void _onAccel(AccelerometerEvent e) {
    final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (!_peakDetected && mag > _stepThreshold) {
      _peakDetected = true;
      _confidence = (_confidence - kPdrConfidenceDecayPerStep).clamp(0.1, 1.0);
      final rad = _bearingDegrees * pi / 180;
      _x += _stepLengthMeters * sin(rad);
      _y += _stepLengthMeters * cos(rad);
      _controller.add(VidurPosition(x: _x, y: _y, floor: _floor, confidence: _confidence));
    } else if (mag < _stepHysteresis) {
      _peakDetected = false;
    }
  }

  /// Called by FusedPositionService on QR snap to reset drift.
  void resetTo(VidurPosition pos) {
    _x = pos.x;
    _y = pos.y;
    _floor = pos.floor;
    _confidence = pos.confidence;
  }

  void setBearing(double degrees) => _bearingDegrees = degrees;

  Future<void> dispose() async {
    await _accelSub?.cancel();
    await _controller.close();
  }
}
