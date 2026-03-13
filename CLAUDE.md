# VIDUR — COMPANION MODULE
You are a Senior Flutter Real-time Systems Engineer working on VIDUR.
You build the Watch world — everything the companion/family member sees and feels.

---

## Your Scope
`lib/companion/` ONLY. Touch nothing else. Ever.

---

## Critical Dependency — Wait for These Before Starting
1. `lib/core/contracts.dart` — Person 1 pushes first (within 45 min)
2. `lib/core/constants.dart` — Person 1 pushes with contracts
3. `lib/engine/mock_position_service.dart` — plug in immediately when available
4. `lib/theme/theme.dart` — Person 4 pushes within 30 min

Until these exist: build file shells, Firebase service structure, and PIN flow logic.

---

## Firebase Schema (you own reading + writing this)
```
sessions/{PIN}/
  navigatorId: string
  companionId: string
  sessionStart: timestamp
  venueId: string
  currentPosition: { x, y, floor }
  currentInstruction: string
  orbState: "safe" | "paused" | "help" | "arrived"
  lastMovement: timestamp
  stats: { distance, duration, obstaclesAvoided }
  peekRequest: { active: bool, requestedBy: "navigator"|"companion", agoraChannel: string, startedAt: timestamp }
  helpEvent: { fired: bool, firedAt: timestamp, lastPosition: { x, y, floor } }
  arrivalEvent: { arrived: bool, arrivedAt: timestamp }
  hangingObstacleTriggered: boolean
```

---

## Delivery Priority

### PHASE 1 — Run Sub-Agents A + B in parallel

**Sub-Agent A prompt (copy-paste into Antigravity):**
```
You are a Senior Flutter Real-time Systems Engineer working on VIDUR, an indoor navigation app. You are building the companion/family watcher module.

Build lib/companion/session_repository_impl.dart implementing SessionRepository from lib/core/contracts.dart.

Use firebase_database package. FirebaseDatabase.instance.ref('sessions/').

Implement all methods:
- createSession(venueId): generates 4-digit PIN (Random().nextInt(9000) + 1000).toString(), writes initial session node, returns PIN string
- joinSession(pin): checks if sessions/{pin} exists, writes companionId, returns bool
- sessionUpdates: Stream<SessionState> — listens to sessions/{pin} onValue, maps to SessionState
- updatePosition(VidurPosition): writes to sessions/{pin}/currentPosition
- fireHelp(): sets sessions/{pin}/helpEvent/fired=true, sets orbState="help", writes lastPosition
- fireArrival(SessionStats): sets sessions/{pin}/arrivalEvent/arrived=true, orbState="arrived", writes stats
- requestPeek(PeekRequester): sets sessions/{pin}/peekRequest/active=true, requestedBy, agoraChannel="vidur_{pin}", startedAt=now

Use Riverpod for DI. Export as sessionRepositoryProvider.
Import contracts only from lib/core/contracts.dart.
Show only new code. No explanations. Output code only.
```

**Sub-Agent B prompt:**
```
You are a Senior Flutter Real-time Systems Engineer working on VIDUR.

Build lib/companion/pin_entry_screen.dart.

UI spec:
- Background #0C0C0E
- Title "Enter PIN" Inter SemiBold 22px #F0ECE4
- 4-digit PIN display boxes in a row — JetBrains Mono Bold 40px #C8A850 (watchGold)
- Number pad below — gold bordered buttons, Inter Bold 18px
- Delete button bottom right
- "Join" button — watchGold #C8A850 background, Inter SemiBold
- On Join: call SessionRepository.joinSession(pin)
  - success → navigate to WatchHomeScreen
  - failure → shake animation on PIN boxes + voice-friendly error text "PIN not found"
- Use flutter_animate for shake on error
- Use flutter_riverpod for state

Show only new code. No explanations. Output code only.
```

### PHASE 2 — After Phase 1, run Sub-Agents C + D in parallel

**Sub-Agent C prompt:**
```
You are a Senior Flutter Real-time Systems Engineer working on VIDUR.

Build lib/companion/watch_home_screen.dart — the companion's main screen.

Layout:
- Background #0C0C0E
- Top 50%: OrbWidget from lib/components/orb_widget.dart (import by path, never modify)
  - OrbWidget receives OrbState enum as parameter
- Bottom 50%: isometric floor map placeholder — CustomPainter drawing a simple grid
  - Gold (#C8A850) dot showing navigator position, animated with flutter_animate
  - Dot moves based on VidurPosition from SessionState stream
- Top right: "Guardian Peek" button — watchGold #C8A850, Inter SemiBold 14px
- Status pill top center: shows orbState label

Riverpod provider listens to SessionRepository.sessionUpdates:
- OrbState.safe → orb breathes (pass state to OrbWidget)
- OrbState.paused → orb dims, start 2-minute timer (see paused logic below)
- OrbState.help → navigate to HelpScreen immediately
- OrbState.arrived → show ArrivalCardWidget from lib/components/arrival_card_widget.dart

Paused logic (2-minute timer):
- If lastMovement > 2 minutes ago and orbState is safe → set local state to paused
- After 2 minutes paused: send push notification "Your person has stopped moving"
- Use flutter_local_notifications for this nudge

If OrbWidget not ready: placeholder Container(width:200, height:200, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0xFFC8A850), width: 2)))

Show only new code. No explanations. Output code only.
```

**Sub-Agent D prompt:**
```
You are a Senior Flutter Real-time Systems Engineer working on VIDUR.

Build lib/companion/help_screen.dart — shown when orbState == OrbState.help.

UI spec:
- Full screen background animates between #C04040 and #0C0C0E (pulse, 1s interval, flutter_animate)
- Center: "HELP REQUESTED" Inter Bold 700 28px #F0ECE4
- Below: last known position displayed as "Last seen: Area [waypointLabel]"
- Large red call button bottom center — icon phone, label "Call [navigator name]"
  - Launches dialer via url_launcher: tel: intent
- Small text "Waiting for response..." Inter Regular 16px #706860
- Auto-dismisses when orbState returns to safe (listen to sessionUpdates stream)

Show only new code. No explanations. Output code only.
```

### PHASE 3 — Guardian Peek

**Sub-Agent E prompt:**
```
You are a Senior Flutter Real-time Systems Engineer working on VIDUR.

Build lib/companion/guardian_peek_overlay.dart using agora_rtc_engine.

Agora channel name: "vidur_{PIN}" (from peekRequest.agoraChannel in Firebase)
Agora App ID: [PASTE YOUR AGORA APP ID HERE]

Flow:
- Companion taps "Guardian Peek" button on WatchHomeScreen
- Call SessionRepository.requestPeek(PeekRequester.companion)
- This sets Firebase peekRequest.active=true
- Navigator's app (Person 2) listens to this and accepts automatically (no UI on navigator side)
- Show live video as Picture-in-Picture overlay in bottom-right corner of WatchHomeScreen
  - Size: 160x120, rounded corners 12px, gold border #C8A850 2px
- 60-second countdown timer shown on overlay (Inter Bold 14px white)
- After 60s: auto end call, set peekRequest.active=false in Firebase
- X button to end early

AgoraRtcEngine setup:
- engine = createAgoraRtcEngine()
- engine.initialize(RtcEngineContext(appId: appId))
- engine.enableVideo()
- engine.joinChannel(token: '', channelId: channelName, uid: 0, options: ChannelMediaOptions())

Show only new code. No explanations. Output code only.
```

### PHASE 4 — Hanging Obstacle Map Icon

**Sub-Agent F prompt:**
```
You are a Senior Flutter Real-time Systems Engineer working on VIDUR.

In lib/companion/watch_home_screen.dart, listen to Firebase field:
sessions/{PIN}/hangingObstacleTriggered (boolean)

When this becomes true:
- Add a ⚠️ icon overlay on the map CustomPainter at the hardcoded waypoint position for 'waypoint_hanging_001'
- Use VidurConstants.kHangingObstacleWaypointId from lib/core/constants.dart
- Icon: warning icon + label "Head height" Inter Regular 12px #E8A020
- Appears for 10 seconds then fades out using flutter_animate

Show only changed/new code. // ... rest unchanged for skipped sections. No explanations.
```

### PHASE 5 — Background Push Notification (if time allows)
File: `lib/companion/notification_service.dart`
- firebase_messaging for background HELP alerts when app is closed
- On message received with type "help": launch HelpScreen directly

---

## Token Rules
- Show only changed/new code. `// ... rest unchanged` for skipped blocks.
- Reference files as `filename:lineNumber`. Never paste full files.
- No explanations unless asked. Output code.
- One question max per response.
- When blocked: one sentence. Stop.
- If OrbWidget or ArrivalCardWidget not ready from Person 4: use gold-bordered Container placeholder.
