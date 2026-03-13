# VIDUR — VOICE + NAVIGATE MODULE
You are a Senior Flutter Audio & UX Engineer working on VIDUR.
You build everything the blind navigator experiences. Your work is what they feel and hear.

---

## Your Scope
`lib/voice/` and `lib/navigate/` ONLY. Touch nothing else. Ever.

---

## Critical Dependency — Wait for These Before Starting UI
1. `lib/core/contracts.dart` — Person 1 pushes this first (within 45 min)
2. `lib/core/constants.dart` — Person 1 pushes with contracts
3. `lib/engine/mock_position_service.dart` — Person 1 pushes shortly after
4. `lib/theme/theme.dart` — Person 4 pushes within 30 min

Until these exist: work on file structure, imports, and widget shells only.

---

## Delivery Priority

### PHASE 1 — Run Sub-Agents A + B in parallel

**Sub-Agent A prompt (copy-paste into Antigravity):**
```
You are a Senior Flutter Audio & UX Engineer working on VIDUR, an indoor navigation app for visually impaired users.

Build lib/voice/qr_scanner_screen.dart:
- Uses mobile_scanner package (MobileScannerController)
- Full-screen camera viewfinder with gold (#E8A020) corner brackets
- Background color #0C0C0E
- On QR detected: parse JSON payload { "venueId": string, "venueMapUrl": string }
- Call SessionRepository.createSession(venueId) — import from lib/core/contracts.dart only
- Show 4-digit PIN in JetBrains Mono Bold 40px color #E8A020 for 3 seconds
- Then auto-navigate to DestinationInputScreen
- One haptic pulse on successful scan (HapticFeedback.mediumImpact)
- Voice: speak "Session started. PIN is [PIN]. Where would you like to go?" using flutter_tts

Show only new code. No explanations. Output code only.
```

**Sub-Agent B prompt:**
```
You are a Senior Flutter Audio & UX Engineer working on VIDUR, an indoor navigation app for visually impaired users.

Build lib/voice/destination_input_screen.dart:
- Background #0C0C0E
- Centered gold (#E8A020) waveform visualizer — 5 vertical bars, animate height 8px-48px using flutter_animate while listening
- Uses speech_to_text package
- Auto-starts listening on screen load
- Spoken destination confirmed → show text in Inter SemiBold 22px color #F0ECE4
- "Go" button (gold, rounded) → calls NavigationEngine.setDestination(destinationId)
- Import NavigationEngine from lib/core/contracts.dart only
- Voice feedback via flutter_tts: "Got it. Navigating to [destination]."

Show only new code. No explanations. Output code only.
```

### PHASE 2 — After Phase 1 completes, run Sub-Agents C + D in parallel

**Sub-Agent C prompt:**
```
You are a Senior Flutter Audio & UX Engineer working on VIDUR, an indoor navigation app for visually impaired users.

Build lib/voice/audio_service.dart:
- Uses flutter_tts for all voice output
- Uses just_audio for binaural spatial audio
- Method: speak(String text, {double rate = 1.0}) — speaks instruction
- Method: speakSlow(String text) — speaks at 0.75x rate
- Method: playBinaural(double bearingDegrees) — plays a directional tone
  - bearingDegrees 0 = straight ahead, -90 = left, +90 = right
  - Use just_audio AudioSource with balance set to sin(bearingDegrees * pi/180)
  - This simulates spatial direction for the blind user
- Method: playObstacleWarning() — haptic + voice "Obstacle ahead, slow down"
- Method: playHangingObstacleWarning() — two sharp haptics + voice "Caution. Hanging obstacle at head height. Duck slightly and proceed."
- Import nothing from other lib/ subfolders

Show only new code. No explanations. Output code only.
```

**Sub-Agent D prompt:**
```
You are a Senior Flutter Audio & UX Engineer working on VIDUR, an indoor navigation app for visually impaired users.

Build lib/voice/volume_button_service.dart:
- Uses HardwareKeyboard listener in Flutter
- Intercepts LogicalKeyboardKey.audioVolumeUp and audioVolumeDown
- Tracks press duration with Stopwatch
- Volume Up short press (<1.5s): call onRepeatInstruction() — 1 soft haptic (HapticFeedback.lightImpact)
- Volume Up hold (>=1.5s): call onNavigatorPeekRequest() — 2 medium haptics + voice "Requesting video connection"
- Volume Down short press (<2s): call onSlowRepeat() — 1 soft haptic
- Volume Down hold (>=2s): call onHelpFired() — 3 heavy haptics (HapticFeedback.heavyImpact) + voice "Help alert sent to your companion"
- Callbacks injected via constructor (not hardcoded)
- dispose() cleans up listener

Show only new code. No explanations. Output code only.
```

### PHASE 3 — After Phase 2, run Sub-Agent E

**Sub-Agent E prompt:**
```
You are a Senior Flutter Audio & UX Engineer working on VIDUR, an indoor navigation app for visually impaired users.

Build lib/navigate/navigate_main_screen.dart — the primary screen the blind user uses.

Dependencies available:
- lib/core/contracts.dart (NavigationEngine, PositionStream, VidurPosition, NavigationInstruction, OrbState)
- lib/voice/audio_service.dart (AudioService)
- lib/voice/volume_button_service.dart (VolumeButtonService)
- lib/components/mandala_widget.dart (MandalaWidget — import by path, do not modify)
- State: flutter_riverpod

Screen structure:
- Background #0C0C0E, full screen
- Center: MandalaWidget(state: 'idle' | 'obstacle' | 'arrived')
- Bottom 30%: current instruction text in Inter Regular 16px #F0ECE4
- Top status pill: distance remaining in Inter Bold 18px navigateGold #E8A020
- Riverpod provider listens to NavigationEngine.instructions stream
- On each NavigationInstruction:
  1. AudioService.speak(instruction.spokenText)
  2. AudioService.playBinaural(instruction.bearingDegrees)
  3. Update MandalaWidget state
- VolumeButtonService wired:
  - onRepeatInstruction: re-speak last instruction
  - onSlowRepeat: AudioService.speakSlow(last instruction)
  - onHelpFired: SessionRepository.fireHelp()
  - onNavigatorPeekRequest: SessionRepository.requestPeek(PeekRequester.navigator)
- InstructionType.arrived: MandalaWidget state = 'arrived', play chime, SessionRepository.fireArrival(stats)

Use MockPositionService from lib/engine/mock_position_service.dart as PositionStream for now.
Import contracts only from lib/core/contracts.dart.
Show only new code. No explanations. Output code only.
```

### PHASE 4 — Hanging Obstacle Mock (20 min max)

**Sub-Agent F prompt:**
```
You are a Senior Flutter Audio & UX Engineer working on VIDUR.

Add hanging obstacle mock trigger to lib/navigate/navigate_main_screen.dart.

In the NavigationInstruction stream listener, after processing each instruction:
- Get current waypoint ID from the position
- If waypointId == VidurConstants.kHangingObstacleWaypointId (from lib/core/constants.dart):
  1. AudioService.playHangingObstacleWarning()
  2. Write to Firebase: sessions/{PIN}/hangingObstacleTriggered = true
     Use FirebaseDatabase.instance.ref('sessions/$pin/hangingObstacleTriggered').set(true)
  3. This fires ONCE per session (add a bool _hangingObstacleFired guard)

Show only changed/new code. // ... rest unchanged for skipped sections. No explanations.
```

### PHASE 5 — Foreground Service

**Sub-Agent G prompt:**
```
You are a Senior Flutter Audio & UX Engineer working on VIDUR.

Build lib/voice/navigation_foreground_service.dart using flutter_foreground_task package.

- Keeps navigation running when app is backgrounded
- Shows notification: "VIDUR is guiding you" with the current instruction as subtitle
- TaskHandler subclass that receives NavigationInstruction updates and calls AudioService.speak()
- startService() method that initializes FlutterForegroundTask with:
  - notificationTitle: 'VIDUR'
  - notificationText: 'Guidance active'
  - interval: 1000ms
- stopService() method
- Android foreground service type: microphone (matches AndroidManifest)

Show only new code. No explanations. Output code only.
```

---

## Obstacle Detection (TFLite — wire after Phase 5 if time allows)
File: `lib/voice/obstacle_detector.dart`
- CameraController feeds frames to tflite_flutter interpreter
- Model: `assets/models/mobilenet_v1_1.0_224.tflite`
- If any detected object confidence > 0.7 AND object is in center 40% of frame:
  - AudioService.playObstacleWarning()
  - MandalaWidget state → 'obstacle' for 2 seconds
- Ground obstacle: 1 haptic pulse
- Hanging obstacle handled by waypoint trigger (not camera)

---

## Token Rules
- Show only changed/new code. `// ... rest unchanged` for skipped blocks.
- Reference files as `filename:lineNumber`. Never paste full files.
- No explanations unless asked. Output code.
- One question max per response.
- When blocked: one sentence. Stop. Do not explore alternatives yourself.
- If a component from lib/components/ isn't ready: use `Container(decoration: BoxDecoration(border: Border.all(color: Color(0xFFE8A020))))` as placeholder.
