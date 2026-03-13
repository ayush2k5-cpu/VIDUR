// lib/engine/venue_map.dart — Person 1 owns this file.

import 'dart:math';
import '../core/contracts.dart';

extension VenueMapLoader on VenueMap {
  static VenueMap fromJson(Map<String, dynamic> json) => VenueMap(
        venueId: json['venueId'] as String,
        waypoints: (json['waypoints'] as List)
            .map((w) => Waypoint(
                  id: w['id'] as String,
                  x: (w['x'] as num).toDouble(),
                  y: (w['y'] as num).toDouble(),
                  floor: w['floor'] as int,
                  label: w['label'] as String?,
                  isHangingObstacle: w['isHangingObstacle'] as bool? ?? false,
                ))
            .toList(),
        edges: (json['edges'] as List)
            .map((e) => WaypointEdge(
                  fromId: e['fromId'] as String,
                  toId: e['toId'] as String,
                  distanceMeters: (e['distanceMeters'] as num).toDouble(),
                ))
            .toList(),
      );

  Waypoint nearestWaypoint(double x, double y, int floor) =>
      waypoints.where((w) => w.floor == floor).reduce((a, b) {
        final da = pow(a.x - x, 2) + pow(a.y - y, 2);
        final db = pow(b.x - x, 2) + pow(b.y - y, 2);
        return da < db ? a : b;
      });
}
