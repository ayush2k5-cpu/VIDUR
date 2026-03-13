// lib/engine/wifi_fingerprint_service.dart — Person 1 owns this file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../core/constants.dart';
import '../core/contracts.dart';

class _Fingerprint {
  final double x, y;
  final int floor;
  final Map<String, int> rssi; // bssid -> dBm
  const _Fingerprint({required this.x, required this.y, required this.floor, required this.rssi});
}

class WifiFingerprintService implements PositionStream {
  final _controller = StreamController<VidurPosition>.broadcast();
  List<_Fingerprint> _fingerprints = [];
  Timer? _timer;

  @override
  Stream<VidurPosition> get positionUpdates => _controller.stream;

  @override
  Future<void> initialize(VenueMap venue) async {
    await _loadFingerprints();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _scan());
  }

  Future<void> _loadFingerprints() async {
    final raw = await rootBundle.loadString('assets/venue/fingerprints.json');
    final list = jsonDecode(raw) as List;
    _fingerprints = list
        .map((f) => _Fingerprint(
              x: (f['x'] as num).toDouble(),
              y: (f['y'] as num).toDouble(),
              floor: f['floor'] as int,
              rssi: Map<String, int>.from(f['rssi'] as Map),
            ))
        .toList();
  }

  Future<void> _scan() async {
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) return;
    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();
    if (results.isEmpty || _fingerprints.isEmpty) return;
    final scanMap = {for (final r in results) r.bssid: r.level};
    final match = _bestMatch(scanMap);
    if (match != null) _controller.add(match);
  }

  VidurPosition? _bestMatch(Map<String, int> scan) {
    double bestConf = 0;
    _Fingerprint? best;
    for (final fp in _fingerprints) {
      final conf = _similarity(scan, fp.rssi);
      if (conf > bestConf) {
        bestConf = conf;
        best = fp;
      }
    }
    if (best == null || bestConf < kWifiMatchThreshold) return null;
    return VidurPosition(x: best.x, y: best.y, floor: best.floor, confidence: bestConf);
  }

  /// Normalized similarity: 1.0 = perfect match, decays with RMSE.
  double _similarity(Map<String, int> a, Map<String, int> b) {
    final keys = {...a.keys, ...b.keys};
    if (keys.isEmpty) return 0;
    double sumSq = 0;
    for (final k in keys) {
      final diff = (a[k] ?? -100) - (b[k] ?? -100);
      sumSq += diff * diff;
    }
    final rmse = sqrt(sumSq / keys.length);
    return exp(-rmse / 25.0); // 25 dBm scale factor
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _controller.close();
  }
}
