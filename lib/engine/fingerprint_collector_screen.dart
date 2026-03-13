// lib/engine/fingerprint_collector_screen.dart — Person 1 owns this file.
// USE AT VENUE: 8:25–8:50 AM to collect RSSI fingerprints at each waypoint.
// After all 6 waypoints are scanned, tap EXPORT → copy JSON → paste into
// assets/venue/fingerprints.json → hot-restart the app.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../theme/theme.dart';
import 'venue_map.dart';

/// Internal model — one collected fingerprint entry.
class _WpFingerprint {
  final String waypointId;
  final double x, y;
  final int floor;
  Map<String, int> rssi = {}; // bssid/ssid → dBm
  bool scanning = false;

  _WpFingerprint({
    required this.waypointId,
    required this.x,
    required this.y,
    required this.floor,
  });

  bool get collected => rssi.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'floor': floor,
        'rssi': rssi,
      };
}

class FingerprintCollectorScreen extends StatefulWidget {
  const FingerprintCollectorScreen({super.key});

  @override
  State<FingerprintCollectorScreen> createState() =>
      _FingerprintCollectorScreenState();
}

class _FingerprintCollectorScreenState
    extends State<FingerprintCollectorScreen> {
  List<_WpFingerprint> _entries = [];
  bool _loading = true;
  String? _loadError;
  String? _statusMessage;

  // Anchor SSIDs — always shown first in per-entry detail.
  static const _anchorSsids = ['VIDUR_A', 'VIDUR_B', 'VIDUR_C'];

  @override
  void initState() {
    super.initState();
    _loadWaypoints();
  }

  Future<void> _loadWaypoints() async {
    try {
      final raw =
          await rootBundle.loadString('assets/venue/test_venue.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final venue = VenueMapLoader.fromJson(json);
      setState(() {
        _entries = venue.waypoints
            .map((w) => _WpFingerprint(
                  waypointId: w.id,
                  x: w.x,
                  y: w.y,
                  floor: w.floor,
                ))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _scanWaypoint(_WpFingerprint entry) async {
    setState(() {
      entry.scanning = true;
      _statusMessage = 'Scanning ${entry.waypointId}…';
    });

    try {
      // Check permission / capability.
      final canStart = await WiFiScan.instance.canStartScan();
      if (canStart != CanStartScan.yes) {
        _showSnack('Cannot scan: $canStart');
        setState(() => entry.scanning = false);
        return;
      }

      await WiFiScan.instance.startScan();

      // Brief settle — let the scan complete.
      await Future.delayed(const Duration(seconds: 2));

      final results = await WiFiScan.instance.getScannedResults();
      if (results.isEmpty) {
        _showSnack('No networks found — try again.');
        setState(() => entry.scanning = false);
        return;
      }

      // Build RSSI map keyed by SSID (fallback to BSSID if SSID empty).
      final rssiMap = <String, int>{};
      for (final r in results) {
        final key = (r.ssid.isNotEmpty) ? r.ssid : r.bssid;
        // Keep strongest reading if SSID appears on multiple BSSIDs.
        if (!rssiMap.containsKey(key) || r.level > rssiMap[key]!) {
          rssiMap[key] = r.level;
        }
      }

      setState(() {
        entry.rssi = rssiMap;
        entry.scanning = false;
        _statusMessage =
            '✓ ${entry.waypointId}: ${rssiMap.length} networks';
      });
    } catch (e) {
      _showSnack('Scan error: $e');
      setState(() => entry.scanning = false);
    }
  }

  void _clearWaypoint(_WpFingerprint entry) {
    setState(() {
      entry.rssi = {};
      _statusMessage = '${entry.waypointId} cleared.';
    });
  }

  int get _collectedCount => _entries.where((e) => e.collected).length;

  String _buildExportJson() {
    final list = _entries
        .where((e) => e.collected)
        .map((e) => e.toJson())
        .toList();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(list);
  }

  Future<void> _exportToClipboard() async {
    if (_collectedCount == 0) {
      _showSnack('Nothing to export — scan at least one waypoint first.');
      return;
    }
    final json = _buildExportJson();
    await Clipboard.setData(ClipboardData(text: json));
    _showSnack(
        '✓ Copied! Paste into assets/venue/fingerprints.json then hot-restart.');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'FINGERPRINT COLLECTOR',
          style: AppTextStyles.screenTitle.copyWith(
            fontSize: 16,
            letterSpacing: 2,
            color: AppColors.navigateGold,
          ),
        ),
        actions: [
          _ExportButton(
            count: _collectedCount,
            total: _entries.length,
            onTap: _exportToClipboard,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _StatusBar(message: _statusMessage),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navigateGold));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingL),
          child: Text(
            'Failed to load venue map:\n$_loadError',
            style: AppTextStyles.body.copyWith(color: AppColors.alertRed),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingM, vertical: AppSpacing.paddingM),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _WaypointCard(
        entry: _entries[i],
        anchorSsids: _anchorSsids,
        onScan: () => _scanWaypoint(_entries[i]),
        onClear: () => _clearWaypoint(_entries[i]),
      ),
    );
  }
}

// ─── Waypoint Card ────────────────────────────────────────────────────────────

class _WaypointCard extends StatelessWidget {
  final _WpFingerprint entry;
  final List<String> anchorSsids;
  final VoidCallback onScan;
  final VoidCallback onClear;

  const _WaypointCard({
    required this.entry,
    required this.anchorSsids,
    required this.onScan,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final done = entry.collected;
    final borderColor =
        done ? AppColors.safeGreen : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(color: borderColor, width: done ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row
            Row(children: [
              _StatusDot(done: done, scanning: entry.scanning),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.waypointId,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      'x=${entry.x.toStringAsFixed(1)}  '
                      'y=${entry.y.toStringAsFixed(1)}  '
                      'floor=${entry.floor}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (entry.scanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.navigateGold),
                )
              else ...[
                _ActionChip(
                    label: done ? 'RE-SCAN' : 'SCAN',
                    color: done
                        ? AppColors.watchGold
                        : AppColors.navigateGold,
                    onTap: onScan),
                if (done) ...[
                  const SizedBox(width: 6),
                  _ActionChip(
                      label: '✕',
                      color: AppColors.alertRed,
                      onTap: onClear),
                ],
              ],
            ]),

            // ── RSSI results
            if (done) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),
              _RssiTable(rssi: entry.rssi, anchorSsids: anchorSsids),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── RSSI table ───────────────────────────────────────────────────────────────

class _RssiTable extends StatelessWidget {
  final Map<String, int> rssi;
  final List<String> anchorSsids;

  const _RssiTable({required this.rssi, required this.anchorSsids});

  @override
  Widget build(BuildContext context) {
    // Anchors first, then the rest sorted by signal strength.
    final anchors = anchorSsids
        .where((s) => rssi.containsKey(s))
        .map((s) => MapEntry(s, rssi[s]!));
    final others = rssi.entries
        .where((e) => !anchorSsids.contains(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final rows = [...anchors, ...others];

    return Column(
      children: rows.map((e) {
        final isAnchor = anchorSsids.contains(e.key);
        final bar = _signalBar(e.value);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            SizedBox(
              width: 140,
              child: Text(
                e.key,
                style: AppTextStyles.caption.copyWith(
                  color: isAnchor
                      ? AppColors.navigateGold
                      : AppColors.textSecondary,
                  fontWeight:
                      isAnchor ? FontWeight.w600 : FontWeight.w400,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: bar,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    isAnchor ? AppColors.navigateGold : AppColors.textSecondary,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              child: Text(
                '${e.value} dBm',
                style: AppTextStyles.caption.copyWith(
                  color: isAnchor
                      ? AppColors.navigateGold
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  /// Map dBm (-100…0) → 0.0…1.0 for bar width.
  double _signalBar(int dbm) => ((dbm + 100) / 100).clamp(0.0, 1.0);
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final bool done;
  final bool scanning;
  const _StatusDot({required this.done, required this.scanning});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scanning
              ? AppColors.watchGold
              : done
                  ? AppColors.safeGreen
                  : AppColors.border,
        ),
      );
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(AppSpacing.radiusS),
          ),
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(
              color: color,
              fontSize: 12,
            ),
          ),
        ),
      );
}

class _ExportButton extends StatelessWidget {
  final int count;
  final int total;
  final VoidCallback onTap;
  const _ExportButton(
      {required this.count, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.copy_all, size: 18, color: AppColors.navigateGold),
        label: Text(
          'EXPORT ($count/$total)',
          style: AppTextStyles.buttonLabel.copyWith(
            color: AppColors.navigateGold,
            fontSize: 13,
          ),
        ),
      );
}

class _StatusBar extends StatelessWidget {
  final String? message;
  const _StatusBar({this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingM, vertical: 10),
      child: SafeArea(
        top: false,
        child: Text(message!, style: AppTextStyles.caption),
      ),
    );
  }
}
