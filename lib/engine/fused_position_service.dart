// lib/engine/fused_position_service.dart — Person 1 owns this file.
// Fusion logic: QR dominates (conf 1.0, resets PDR drift).
// Between snaps: weighted average of PDR + WiFi (if WiFi >= kWifiMatchThreshold).
// Output: 1 Hz stream.

import 'dart:async';
import '../core/constants.dart';
import '../core/contracts.dart';
import 'qr_waypoint_service.dart';
import 'pdr_service.dart';
import 'wifi_fingerprint_service.dart';

class FusedPositionService implements PositionStream {
  final QrWaypointService _qr;
  final PdrService _pdr;
  final WifiFingerprintService _wifi;

  VidurPosition? _lastPdr;
  VidurPosition? _lastWifi;

  final _controller = StreamController<VidurPosition>.broadcast();
  Timer? _outputTimer;
  StreamSubscription? _qrSub, _pdrSub, _wifiSub;

  FusedPositionService({
    QrWaypointService? qr,
    PdrService? pdr,
    WifiFingerprintService? wifi,
  })  : _qr = qr ?? QrWaypointService(),
        _pdr = pdr ?? PdrService(),
        _wifi = wifi ?? WifiFingerprintService();

  @override
  Stream<VidurPosition> get positionUpdates => _controller.stream;

  @override
  Future<void> initialize(VenueMap venue) async {
    await Future.wait([
      _qr.initialize(venue),
      _pdr.initialize(venue),
      _wifi.initialize(venue),
    ]);

    _qrSub = _qr.positionUpdates.listen((pos) {
      _pdr.resetTo(pos);           // reset PDR drift counter
      _controller.add(pos);        // QR dominates immediately at confidence 1.0
    });

    _pdrSub = _pdr.positionUpdates.listen((pos) => _lastPdr = pos);
    _wifiSub = _wifi.positionUpdates.listen((pos) => _lastWifi = pos);

    _outputTimer = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
  }

  void _emit() {
    final pdr = _lastPdr;
    if (pdr == null) return;

    final wifi = _lastWifi;
    if (wifi == null || wifi.confidence < kWifiMatchThreshold) {
      _controller.add(pdr);
      return;
    }

    final total = pdr.confidence + wifi.confidence;
    _controller.add(VidurPosition(
      x: (pdr.x * pdr.confidence + wifi.x * wifi.confidence) / total,
      y: (pdr.y * pdr.confidence + wifi.y * wifi.confidence) / total,
      floor: pdr.floor,
      confidence: total / 2.0,
    ));
  }

  Future<void> dispose() async {
    _outputTimer?.cancel();
    await Future.wait([
      _qrSub?.cancel() ?? Future.value(),
      _pdrSub?.cancel() ?? Future.value(),
      _wifiSub?.cancel() ?? Future.value(),
    ]);
    await _controller.close();
  }
}
