# VIDUR — PROJECT SETUP
## Run once. Never open again after all checkboxes are done.

---

## STEP 1 — Flutter Project Scaffold
```bash
cd /path/to/VIDUR
flutter create . --org com.vidur --project-name vidur
```

---

## STEP 2 — Replace pubspec.yaml (full contents)
```yaml
name: vidur
description: Indoor navigation for visually impaired. Zero hardware.
publish_to: none
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Animations & UI
  flutter_animate: ^4.5.0
  animations: ^2.0.11
  google_fonts: ^6.2.1

  # Firebase
  firebase_core: ^3.0.0
  firebase_database: ^11.0.0
  firebase_messaging: ^15.0.0

  # Video — Guardian Peek
  agora_rtc_engine: ^6.3.2

  # Voice
  flutter_tts: ^4.0.2
  speech_to_text: ^7.0.0

  # Navigation & Scanning
  mobile_scanner: ^5.0.0

  # Positioning
  sensors_plus: ^5.0.0        # accelerometer for PDR
  wifi_scan: ^0.4.1           # WiFi RSSI scanning

  # Audio
  just_audio: ^0.9.40

  # Foreground Service
  flutter_foreground_task: ^8.0.0

  # Obstacle Detection
  tflite_flutter: ^0.10.4

  # Haptics
  flutter_vibrate: ^1.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0

flutter:
  uses-material-design: true
  assets:
    - assets/models/
    - assets/fonts/
    - assets/venue/
```

---

## STEP 3 — Create Folder Structure
```bash
mkdir -p lib/core lib/engine lib/voice lib/navigate lib/companion lib/components lib/theme
mkdir -p assets/models assets/fonts assets/venue
touch lib/core/contracts.dart
touch lib/core/constants.dart
touch lib/theme/theme.dart
touch lib/engine/mock_position_service.dart
touch main.dart
```

---

## STEP 4 — Android Permissions
In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:
```xml
<!-- Camera — QR scanning + obstacle detection -->
<uses-permission android:name="android.permission.CAMERA"/>

<!-- Microphone — speech to text -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<!-- WiFi — fingerprinting -->
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Foreground service — background navigation -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Network — Firebase + Agora -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Vibration -->
<uses-permission android:name="android.permission.VIBRATE"/>
```

Inside `<application>`, add:
```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundTaskService"
    android:foregroundServiceType="microphone"
    android:exported="false"/>
```

Set `android:minSdkVersion` to `33` (Android 13).

---

## STEP 5 — Download TFLite Model
Download `mobilenet_v1_1.0_224.tflite` and `labels.txt` from:
https://www.kaggle.com/models/tensorflow/mobilenet-v1
Place both in `assets/models/`.

---

## STEP 6 — Firebase Setup
- Place `google-services.json` in `android/app/`
- In `android/build.gradle`, add to `dependencies`: `classpath 'com.google.gms:google-services:4.4.1'`
- In `android/app/build.gradle`, add at bottom: `apply plugin: 'com.google.gms.google-services'`

---

## STEP 7 — Pre-warm Fonts (requires internet once)
```bash
flutter run
```
Run once with internet connected. Google Fonts caches locally after first load.

---

## STEP 8 — Lock main.dart
After `flutter create`, replace `main.dart` with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: VidurApp()));
}

class VidurApp extends StatelessWidget {
  const VidurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIDUR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Color(0xFF0C0C0E)),
      // TODO Person 4: Replace with full theme + router
      home: const Scaffold(
        body: Center(
          child: Text('VIDUR', style: TextStyle(color: Color(0xFFE8A020), fontSize: 40)),
        ),
      ),
    );
  }
}
```
**main.dart is now locked. Nobody modifies it again except to wire the router.**

---

## STEP 9 — Create Branches
```bash
git add .
git commit -m "scaffold: project setup complete — main locked"
git branch branch/engine
git branch branch/voice-navigate
git branch branch/companion
git branch branch/design
git push origin main branch/engine branch/voice-navigate branch/companion branch/design
```

---

## STEP 10 — Each Person Places Their CLAUDE.md
```bash
# Person 1 on branch/engine:
git checkout branch/engine
cp docs/CLAUDE_ENGINE.md CLAUDE.md
git add CLAUDE.md && git commit -m "claude: engine context loaded"

# Person 2 on branch/voice-navigate:
git checkout branch/voice-navigate
cp docs/CLAUDE_VOICE.md CLAUDE.md
git add CLAUDE.md && git commit -m "claude: voice context loaded"

# Person 3 on branch/companion:
git checkout branch/companion
cp docs/CLAUDE_COMPANION.md CLAUDE.md
git add CLAUDE.md && git commit -m "claude: companion context loaded"

# Person 4 on branch/design:
git checkout branch/design
cp docs/CLAUDE_DESIGN.md CLAUDE.md
git add CLAUDE.md && git commit -m "claude: design context loaded"
```

---

## STEP 11 — Verify Everything
```bash
flutter pub get
flutter analyze
flutter run
```
Clean run with the placeholder screen = setup complete.

---
## SETUP DONE. DO NOT OPEN THIS FILE AGAIN.
