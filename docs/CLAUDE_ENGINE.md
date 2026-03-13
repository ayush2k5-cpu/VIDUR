# VIDUR — ENGINE MODULE
You are a Senior Flutter Positioning Systems Engineer working on VIDUR.
Indoor navigation app for visually impaired. You own the positioning brain.

---

## Your Scope
`lib/core/` and `lib/engine/` ONLY. Touch nothing else. Ever.

---

## Delivery Priority — In This Order. Do Not Skip Ahead.

### PRIORITY 0 — contracts.dart (blocks all 3 teammates)
File: `lib/core/contracts.dart`
Push to branch/engine the moment it compiles. Teammates cannot start without it.

```dart
// lib/core/contracts.dart
abstract class PositionStream {
  Stream<VidurPosition> get positionUpdates;
  Future<void> initialize(VenueMap venue);
}

abstract class NavigationEngine {
  Stream<NavigationInstruction> get instructions;
  Future<void> setDestination(String destinationId);
  Future<void> recalculate();
}

abstract class SessionRepository {
  Future<String> createSession(String venueId);
  Future<bool> joinSession(String pin);
  Stream<SessionState> get sessionUpdates;
  Future<void> updatePosition(VidurPosition position);
  Future<void> fireHelp();
  Future<void> fireArrival(SessionStats stats);
  Future<void> requestPeek(PeekRequester requester);
}

class VidurPosition {
  final double x, y;
  final int floor;
  final double confidence;
  const VidurPosition({required this.x, required this.y, required this.floor, required this.confidence});
}

class NavigationInstruction {
  final String spokenText;
  final double bearingDegrees;
  final double distanceMeters;
  final InstructionType type;
  const NavigationInstruction({required this.spokenText, required this.bearingDegrees, required this.distanceMeters, required this.type});
}

class SessionState {
  final OrbState orbState;
  final VidurPosition? position;
  final String? currentInstruction;
  final DateTime lastMovement;
  const SessionState({required this.orbState, this.position, this.currentInstruction, required this.lastMovement});
}

class SessionStats {
  final double distanceMeters;
  final Duration duration;
  final int obstaclesAvoided;
  const SessionStats({required this.distanceMeters, required this.duration, required this.obstaclesAvoided});
}

class VenueMap {
  final String venueId;
  final List<Waypoint> waypoints;
  final List<WaypointEdge> edges;
  const VenueMap({required this.venueId, required this.waypoints, required this.edges});
}

class Waypoint {
  final String id;
  final double x, y;
  final int floor;
  final String? label;
  final bool isHangingObstacle;
  const Waypoint({required this.id, required this.x, required this.y, required this.floor, this.label, this.isHangingObstacle = false});
}

class WaypointEdge {
  final String fromId, toId;
  final double distanceMeters;
  const WaypointEdge({required this.fromId, required this.toId, required this.distanceMeters});
}

enum OrbState { safe, paused, help, arrived }
enum InstructionType { turn, straight, arrived, obstacle }
enum PeekRequester { navigator, companion }
```

### PRIORITY 1 — constants.dart
File: `lib/core/constants.dart`
```dart
// lib/core/constants.dart
class VidurConstants {
  static const String kHangingObstacleWaypointId = 'waypoint_hanging_001';
  static const int kPauseThresholdSeconds = 120;
  static const int kPeekDurationSeconds = 60;
  static const double kPdrConfidenceDecayPerStep = 0.05;
  static const double kWifiMatchThreshold = 0.6;
}
```

### PRIORITY 2 — MockPositionService (unblocks Granth + Priyanshu)
File: `lib/engine/mock_position_service.dart`
- Implements `PositionStream`
- Emits `VidurPosition` every 2 seconds on a hardcoded 6-point path
- confidence always 0.9
- Loop back to start after reaching end
- Push immediately after contracts.dart. Teammates plug this in same minute.

### PRIORITY 3 — QR Waypoint Service
File: `lib/engine/qr_waypoint_service.dart`
- Processes QR scan results from Person 2's scanner (receives waypoint ID string)
- Returns `VidurPosition` with confidence 1.0
- Resets PDR drift counter to zero on every successful scan
- Exposes: `VidurPosition resolveWaypoint(String waypointId, VenueMap venue)`

### PRIORITY 4 — PDR Service
File: `lib/engine/pdr_service.dart`
- Uses `sensors_plus` accelerometer for step detection
- Peak detection on Z-axis for step count
- Heading from device compass (magnetometer)
- Confidence starts at 0.85, decays by `kPdrConfidenceDecayPerStep` per step since last QR fix
- Exposes stream of `VidurPosition`

### PRIORITY 5 — WiFi Fingerprint Service
File: `lib/engine/wifi_fingerprint_service.dart`
- Uses `wifi_scan` to get current RSSI list
- Loads fingerprint database from `assets/venue/fingerprints.json`
- Match algorithm: Euclidean distance in RSSI space
- Returns confidence = normalized inverse distance (0.0–1.0)
- Below `kWifiMatchThreshold`: confidence = 0.0 (don't use this result)

### PRIORITY 6 — Fused Position Service
File: `lib/engine/fused_position_service.dart`
- Implements `PositionStream`
- Wraps QrWaypointService + PdrService + WifiFingerprintService
- Fusion: `position = weighted_sum(qr * wQR, pdr * wPDR, wifi * wWifi) / totalWeight`
- Weights = confidence values of each source
- QR snap: when QR fires (confidence 1.0), it dominates completely and resets others
- Output: single `VidurPosition` stream at 1Hz

### PRIORITY 7 — Navigation Engine
File: `lib/engine/navigation_engine.dart`
- Implements `NavigationEngine`
- A* pathfinding on `VenueMap.waypoints` + `VenueMap.edges`
- Subscribes to `FusedPositionService`
- On position update: find nearest waypoint, compute next instruction
- `bearingDegrees` = angle from current position to next waypoint (for binaural audio)
- Instruction types: turn (angle > 20°), straight, arrived (within 2m of destination), obstacle

### PRIORITY 8 — Venue Map
File: `lib/engine/venue_map.dart`
- `VenueMap fromJson(Map<String, dynamic> json)` — parses Mappedin export + custom fingerprint overlay
- `Waypoint? nearestWaypoint(VidurPosition pos)` — finds closest waypoint within 3m radius
- Tomorrow at venue: generate `assets/venue/venue_map.json` with real coordinates

---

## Positioning Fusion Logic (reference)
```
Event: QR Waypoint Scanned
→ confidence = 1.0 → snap position exactly → reset PDR drift → dominates fusion output

Between QR Scans:
→ PDR: continuous, confidence decays each step
→ WiFi: continuous, confidence = match score
→ fused = (pdr_pos * pdr_conf + wifi_pos * wifi_conf) / (pdr_conf + wifi_conf)

WiFi congested (low match score → confidence < threshold):
→ PDR carries alone until next QR snap
```

---

## Your Workflow (Antigravity + Claude parallel)
- Use **Claude** for: architecture decisions, contracts review, fusion logic
- Use **Antigravity** for: implementing individual service files
- Build one service at a time. Test against mock data before moving to next.
- After each file: `flutter analyze`. Fix all warnings before continuing.

---

## Token Rules
- Show only changed/new code. `// ... rest unchanged` for skipped blocks.
- Reference files as `filename:lineNumber`. Never paste full files.
- No explanations unless asked. Output code.
- One question max per response.
- When blocked: one sentence describing the exact blocker. Stop.
