# VIDUR — PM Escalation Report
**To:** Project Lead
**From:** Voice Module PM
**Date:** 2026-03-13 | 23:42 IST
**Re:** Pre-execution blockers + codebase errors — Voice + Navigate Module
**Priority:** 🔴 Must resolve before Phase 1 sub-agents are dispatched

---

## 🔴 Pre-Existing Errors Found in Codebase

These are **not sub-agent questions** — these are **actual bugs/mismatches already in the repo** that will cause compile failures if not fixed before Phase 1 starts.

---

### ❌ Error 1 — `VidurConstants` Class Does Not Exist

**File affected:** `lib/core/constants.dart` (Person 1's file)
**Severity:** 🔴 Build-breaking for Phase 4

**What the spec says (CLAUDE_VOICE.md, Phase 4):**
```dart
VidurConstants.kHangingObstacleWaypointId
```

**What `constants.dart` actually exports:**
```dart
// lib/core/constants.dart (line 3)
const String kHangingObstacleWaypointId = 'waypoint_hanging_001';
```
There is no `VidurConstants` class. The constant is a bare top-level declaration.

**Impact:** Sub-Agent F (Phase 4) will generate code referencing `VidurConstants.kHangingObstacleWaypointId`, which will not compile.

**Required action from Person 1 (choose one):**
- **Option A** *(Preferred — 2-min fix)*: Wrap in a class:
  ```dart
  abstract class VidurConstants {
    static const String kHangingObstacleWaypointId = 'waypoint_hanging_001';
  }
  ```
- **Option B**: PM updates the Phase 4 sub-agent prompt to use bare `kHangingObstacleWaypointId` instead.

> **PM Recommendation:** Take Option A. Keeps `constants.dart` consistent with how other modules will reference it as the project grows. Takes 2 minutes.

---

### ❌ Error 2 — `contracts.dart` Missing `waypointId` Field on `VidurPosition`

**File affected:** `lib/core/contracts.dart` (Person 1's file)
**Severity:** 🟠 Logic-breaking for Phase 4

**What Phase 4 requires:**
Sub-Agent F needs to read `waypointId` from the current position to check for the hanging obstacle trigger:
```dart
if (position.waypointId == kHangingObstacleWaypointId) { ... }
```

**What `VidurPosition` currently defines (contracts.dart, lines 8–13):**
```dart
class VidurPosition {
  final double x, y;
  final int floor;
  final double confidence;
  // ← No waypointId field
}
```

**Impact:** Sub-Agent F will have no way to detect which waypoint the user is at. The hanging obstacle mock cannot fire correctly.

**Required action from Person 1:**
Add `waypointId` to `VidurPosition`:
```dart
class VidurPosition {
  final double x, y;
  final int floor;
  final double confidence;
  final String? waypointId;  // ← ADD THIS
  const VidurPosition({
    required this.x, required this.y,
    required this.floor, required this.confidence,
    this.waypointId,
  });
}
```

> **PM Recommendation:** This is required for Phase 4 correctness. Person 1 must push this before Phase 3 is complete.

---

## 🟡 Open Questions — Decisions Required from Lead

These are **design decisions** raised during pre-flight review. Each needs a one-line answer from the lead before sub-agents are dispatched.

---

### ❓ Question 1 — `DestinationInputScreen` Constructor Signature

**Raised by:** Voice Module PM (pre-flight review of Sub-Agent B)
**Affects:** Phase 1 Sub-Agent B, Phase 3 Sub-Agent E (navigates to this screen)

**The ambiguity:**
Sub-Agent A (QR Scanner) auto-navigates to `DestinationInputScreen` after a successful scan. Sub-Agent B builds `DestinationInputScreen`. Sub-Agent E wires both into the navigation flow.

None of the current specs define what `DestinationInputScreen`'s constructor takes. Three plausible options:

| Option | Constructor | Rationale |
|---|---|---|
| **A** | `DestinationInputScreen({required String venueId, required String pin})` | Minimal — pass scan result only |
| **B** | `DestinationInputScreen({required NavigationEngine engine})` | Sub-Agent B calls `engine.setDestination()` directly |
| **C** | `DestinationInputScreen({required String venueId, required String venueMapUrl, required String pin})` | Full context — allows future map rendering |

**Impact if unresolved:** Sub-Agent A will push to `DestinationInputScreen()` with no args; Sub-Agent B will define a different constructor. Phase 3 (E) will see a mismatch and fail.

> **PM Recommendation:** **Option B** — `NavigationEngine` is already the clean abstraction. Keeps sub-agents decoupled from raw session state. Lead to confirm.

---

### ❓ Question 2 — Is `mobile_scanner` an Approved Dependency?

**Raised by:** Voice Module PM
**Affects:** Phase 1 Sub-Agent A (`qr_scanner_screen.dart`)

**The issue:**
`CLAUDE_VOICE.md` lists approved packages for the voice module as:
- `speech_to_text`, `flutter_tts`, `flutter_animate`, `just_audio`, `flutter_foreground_task`

`mobile_scanner` is **used** in Sub-Agent A's spec but **never listed** as an approved dependency for this module.

**Questions for lead:**
1. Is `mobile_scanner` already in `pubspec.yaml`?
2. Who is responsible for adding/approving new packages — PM, Person 1, or lead?

> **PM Recommendation:** Check `pubspec.yaml` now. If absent, add `mobile_scanner: ^5.x` before dispatching Sub-Agent A. This is a 30-second fix but could block Phase 1 entirely if missed.

---

### ❓ Question 3 — Shared Widget Interface Contract (`voice_contracts.dart`)

**Raised by:** Voice Module PM
**Affects:** All phases — cross-agent compatibility

**The problem:**
Sub-Agents A, B, C, D, E are being run independently. Without a shared constructor/interface spec, each agent will design its widget APIs independently. When Phase 3 (Sub-Agent E) tries to wire them together, interface mismatches will likely cause rework.

**Proposed solution:**
Create `lib/voice/voice_contracts.dart` — a lightweight interface file that defines:
```dart
// Widget constructor signatures (not implemented, just documented)
// e.g., DestinationInputScreen({ required NavigationEngine engine })
// AudioService — method signatures
// VolumeButtonService — callback typedef signatures
```

**Two paths:**

| Path | Effort | Risk |
|---|---|---|
| **Create `voice_contracts.dart` now** (before Phase 1) | ~20 min PM + Person 1 | Low — agents stay aligned |
| **Skip it, fix mismatches in Phase 3** | 0 min now | High — Sub-Agent E likely needs one extra iteration |

> **PM Recommendation:** **Create `voice_contracts.dart` now.** It costs 20 minutes upfront and saves 1–2 hours of Phase 3 rework. PM can draft the interface spec; Person 1 approves and pushes.

---

## 📋 Action Summary for Lead

| # | Issue | Owner | Urgency | Decision Needed |
|---|---|---|---|---|
| E1 | `VidurConstants` class missing in `constants.dart` | Person 1 | 🔴 Before Phase 1 | Wrap in class OR PM updates prompt |
| E2 | `VidurPosition` missing `waypointId` field | Person 1 | 🟠 Before Phase 3 complete | Add `String? waypointId` to model |
| Q1 | `DestinationInputScreen` constructor signature | Lead | 🔴 Before Phase 1 | Pick Option A, B, or C |
| Q2 | `mobile_scanner` package approval | Lead / Person 1 | 🔴 Before Phase 1 | Confirm in `pubspec.yaml` |
| Q3 | Create `voice_contracts.dart` interface file | PM + Person 1 | 🟡 Recommended before Phase 1 | Approve or decline |

---

> **PM Status:** Phase 1 is **held** pending lead decisions on E1, Q1, Q2.
> E2 can be deferred to before Phase 3 completes. Q3 is recommended but not blocking.
> All sub-agent prompts are ready. Dispatch takes < 5 minutes once blockers are cleared.
