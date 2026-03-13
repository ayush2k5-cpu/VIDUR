# VIDUR — PROJECT CONTEXT
Named after the wisest counselor from the Mahabharata. Indoor navigation for visually impaired. Zero hardware. Flutter, Android 13+ only.

---

## Architecture
- **State:** Riverpod only. No Provider, no BLoC, no setState except leaf widgets.
- **Backend:** Firebase Realtime Database
- **Video:** Agora RTC (Guardian Peek)
- **Positioning:** QR Waypoints + PDR + WiFi Fingerprinting — fused into one VidurPosition
- **Fonts:** Cormorant Garamond (VIDUR wordmark) | Inter (all UI) | JetBrains Mono (PIN/numbers)

---

## Color Tokens (never hardcode hex, always use AppTheme)
```
background:     #0C0C0E    surface:       #161618
border:         #2A2820    navigateGold:  #E8A020
watchGold:      #C8A850    safeGreen:     #4A9060
alertRed:       #C04040    textPrimary:   #F0ECE4
textSecondary:  #706860
```

---

## Folder Ownership — ABSOLUTE. NEVER CROSS THESE LINES.
```
lib/core/        → Person 1 ONLY
lib/engine/      → Person 1 ONLY
lib/voice/       → Person 2 ONLY
lib/navigate/    → Person 2 ONLY
lib/companion/   → Person 3 ONLY
lib/components/  → Person 4 ONLY
lib/theme/       → Person 4 ONLY
main.dart        → LOCKED
```

---

## Cross-Module Import Rule
Only import from `lib/core/contracts.dart` across module boundaries.
Never import from another person's lib/ subfolder.
Components (lib/components/) are imported by filename only — never modified.

---

## Firebase Schema
```
sessions/{PIN}/
  navigatorId, companionId, sessionStart, venueId
  currentPosition: { x, y, floor }
  currentInstruction: string
  orbState: "safe" | "paused" | "help" | "arrived"
  lastMovement: timestamp
  stats: { distance, duration, obstaclesAvoided }
  peekRequest: { active, requestedBy, agoraChannel, startedAt }
  helpEvent: { fired, firedAt, lastPosition }
  arrivalEvent: { arrived, arrivedAt }
  hangingObstacleTriggered: boolean
```

---

## Hanging Obstacle (cross-branch coordination)
- Shared constant in `lib/core/constants.dart`: `kHangingObstacleWaypointId = 'waypoint_hanging_001'`
- Person 2 writes `hangingObstacleTriggered: true` to Firebase when triggered
- Person 3 listens to that field and renders icon on companion map
- Nobody else touches this field

---

## Token Rules — Applies to Every Session
- Show only changed/new code. Use `// ... rest unchanged` for skipped sections.
- Never paste a full file. Reference by `filename:lineNumber`.
- No explanations unless explicitly asked. Output code.
- One question max per response. Batch all questions.
- No tests unless asked. No docstrings on unchanged code.
- When stuck: state the exact blocker in one sentence. Stop.

---

## Branch Structure
```
main              (locked after scaffold)
├── branch/engine          → Person 1
├── branch/voice-navigate  → Person 2
├── branch/companion       → Person 3
└── branch/design          → Person 4
```

## Merge Order (do not deviate)
1. branch/design → main
2. branch/engine → main
3. branch/voice-navigate → main
4. branch/companion → main

---

## Contracts Reference (lib/core/contracts.dart)
```dart
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
  final double confidence; // 0.0–1.0
}

class NavigationInstruction {
  final String spokenText;
  final double bearingDegrees;
  final double distanceMeters;
  final InstructionType type;
}

class SessionState {
  final OrbState orbState;
  final VidurPosition? position;
  final String? currentInstruction;
  final PeekState? peekState;
  final DateTime lastMovement;
}

class SessionStats {
  final double distanceMeters;
  final Duration duration;
  final int obstaclesAvoided;
}

enum OrbState { safe, paused, help, arrived }
enum InstructionType { turn, straight, arrived, obstacle }
enum PeekRequester { navigator, companion }
```
