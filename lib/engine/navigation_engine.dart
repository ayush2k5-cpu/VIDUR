// lib/engine/navigation_engine.dart — Person 1 owns this file.
// A* on waypoint graph. Outputs NavigationInstruction with bearingDegrees for binaural audio.

import 'dart:async';
import 'dart:math';
import '../core/contracts.dart';

class _Open {
  final double f;
  final String id;
  _Open(this.f, this.id);
}

class VidurNavigationEngine implements NavigationEngine {
  VenueMap? _venue;
  String? _destinationId;
  VidurPosition? _currentPosition;
  StreamSubscription? _positionSub;

  final _controller = StreamController<NavigationInstruction>.broadcast();

  @override
  Stream<NavigationInstruction> get instructions => _controller.stream;

  void attach(PositionStream positionStream, VenueMap venue) {
    _venue = venue;
    _positionSub?.cancel();
    _positionSub = positionStream.positionUpdates.listen((pos) {
      _currentPosition = pos;
      if (_destinationId != null) _recalculate();
    });
  }

  @override
  Future<void> setDestination(String destinationId) async {
    _destinationId = destinationId;
    _recalculate();
  }

  @override
  Future<void> recalculate() async => _recalculate();

  void _recalculate() {
    final venue = _venue;
    final pos = _currentPosition;
    final destId = _destinationId;
    if (venue == null || pos == null || destId == null) return;

    final startId = _nearestWaypointId(venue, pos);
    final path = _aStar(venue, startId, destId);

    if (path.length < 2) {
      _controller.add(const NavigationInstruction(
        spokenText: 'You have arrived at your destination.',
        bearingDegrees: 0,
        distanceMeters: 0,
        type: InstructionType.arrived,
      ));
      return;
    }

    final next = venue.waypoints.firstWhere((w) => w.id == path[1]);
    final bearing = _bearing(pos.x, pos.y, next.x, next.y);
    final dist = _dist(pos.x, pos.y, next.x, next.y);
    final type = next.isHangingObstacle
        ? InstructionType.obstacle
        : (dist < 1.5 ? InstructionType.turn : InstructionType.straight);

    _controller.add(NavigationInstruction(
      spokenText: _buildSpoken(next, bearing, dist),
      bearingDegrees: bearing,
      distanceMeters: dist,
      type: type,
    ));
  }

  String _nearestWaypointId(VenueMap venue, VidurPosition pos) =>
      venue.waypoints
          .where((w) => w.floor == pos.floor)
          .reduce((a, b) {
            final da = pow(a.x - pos.x, 2) + pow(a.y - pos.y, 2);
            final db = pow(b.x - pos.x, 2) + pow(b.y - pos.y, 2);
            return da < db ? a : b;
          })
          .id;

  List<String> _aStar(VenueMap venue, String startId, String goalId) {
    // adjacency: fromId -> {toId: distance}
    final adj = <String, Map<String, double>>{};
    for (final e in venue.edges) {
      adj.putIfAbsent(e.fromId, () => {})[e.toId] = e.distanceMeters;
      adj.putIfAbsent(e.toId, () => {})[e.fromId] = e.distanceMeters;
    }

    final goal = venue.waypoints.firstWhere((w) => w.id == goalId);
    double h(String id) {
      final w = venue.waypoints.firstWhere((wp) => wp.id == id);
      return _dist(w.x, w.y, goal.x, goal.y);
    }

    final open = <_Open>[_Open(h(startId), startId)];
    final gScore = <String, double>{startId: 0};
    final cameFrom = <String, String>{};

    while (open.isNotEmpty) {
      open.sort((a, b) => a.f.compareTo(b.f));
      final current = open.removeAt(0).id;
      if (current == goalId) return _reconstruct(cameFrom, current);
      for (final entry in (adj[current] ?? {}).entries) {
        final tentative = (gScore[current] ?? double.infinity) + entry.value;
        if (tentative < (gScore[entry.key] ?? double.infinity)) {
          cameFrom[entry.key] = current;
          gScore[entry.key] = tentative;
          open.add(_Open(tentative + h(entry.key), entry.key));
        }
      }
    }
    return [];
  }

  List<String> _reconstruct(Map<String, String> cameFrom, String current) {
    final path = [current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path;
  }

  double _bearing(double x1, double y1, double x2, double y2) =>
      (atan2(x2 - x1, y2 - y1) * 180 / pi + 360) % 360;

  double _dist(double x1, double y1, double x2, double y2) =>
      sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));

  String _buildSpoken(Waypoint next, double bearing, double dist) {
    if (next.isHangingObstacle) return 'Warning: overhead obstacle ahead. Duck now.';
    final dir = _bearingToWords(bearing);
    final label = next.label != null ? ' towards ${next.label}' : '';
    return 'In ${dist.round()} metres, $dir$label.';
  }

  String _bearingToWords(double b) {
    if (b < 22.5 || b >= 337.5) return 'continue straight';
    if (b < 67.5) return 'turn sharp right';
    if (b < 112.5) return 'turn right';
    if (b < 157.5) return 'turn slight right';
    if (b < 202.5) return 'turn around';
    if (b < 247.5) return 'turn slight left';
    if (b < 292.5) return 'turn left';
    return 'turn sharp left';
  }

  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _controller.close();
  }
}
