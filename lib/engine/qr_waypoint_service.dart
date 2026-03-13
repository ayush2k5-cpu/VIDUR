// lib/engine/qr_waypoint_service.dart — Person 1 owns this file.

import 'dart:async';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/contracts.dart';

class QrWaypointService implements PositionStream {
  final _controller = StreamController<VidurPosition>.broadcast();
  MobileScannerController? _scanner;
  VenueMap? _venue;

  @override
  Stream<VidurPosition> get positionUpdates => _controller.stream;

  @override
  Future<void> initialize(VenueMap venue) async {
    _venue = venue;
    _scanner = MobileScannerController();
    _scanner!.barcodes.listen(_onBarcode);
    await _scanner!.start();
  }

  void _onBarcode(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || _venue == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final waypointId = data['id'] as String?;
      if (waypointId == null) return;
      final waypoint = _venue!.waypoints.firstWhere((w) => w.id == waypointId);
      _controller.add(VidurPosition(
        x: waypoint.x,
        y: waypoint.y,
        floor: waypoint.floor,
        confidence: 1.0,
        waypointId: waypoint.id,
      ));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _scanner?.dispose();
    await _controller.close();
  }
}
