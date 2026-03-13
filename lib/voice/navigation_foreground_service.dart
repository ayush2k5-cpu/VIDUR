// lib/voice/navigation_foreground_service.dart
// Phase 5 — Foreground service to keep VIDUR navigation alive when backgrounded.
//
// Architecture (flutter_foreground_task ^8.0.0):
//   - NavigationTaskHandler  extends TaskHandler  (lives in background isolate)
//   - NavigationForegroundService  (UI-side helper — start / stop / send)
//
// Usage from NavigateMainScreen:
//   await NavigationForegroundService.startService();
//   NavigationForegroundService.updateInstruction('Turn left in 10 metres');
//   await NavigationForegroundService.stopService();
//
// Call FlutterForegroundTask.initCommunicationPort() early in main().

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:vidur/voice/audio_service.dart';

// ─── Task Handler ─────────────────────────────────────────────────────────────
// Runs inside the background isolate created by flutter_foreground_task.
// Must be a top-level or static function.

@pragma('vm:entry-point')
void startNavigationCallback() {
  FlutterForegroundTask.setTaskHandler(NavigationTaskHandler());
}

class NavigationTaskHandler extends TaskHandler {
  final AudioService _audio = AudioService();
  String _lastInstruction = '';

  // Called once when the foreground service starts.
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _lastInstruction = 'VIDUR guidance active';
  }

  // Called on every interval tick (every 1 000 ms as configured).
  // We do not re-speak on every tick — only on explicit data from the UI.
  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Update the notification subtitle with the current instruction
    if (_lastInstruction.isNotEmpty) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'VIDUR',
        notificationText: _lastInstruction,
      );
    }
  }

  // Called when data is sent from the UI isolate via sendDataToTask().
  // Expected payload: a plain String — the spoken instruction text.
  @override
  Future<void> onReceiveData(Object data) async {
    if (data is String && data.isNotEmpty) {
      _lastInstruction = data;
      // Speak the instruction in the background
      await _audio.speak(data);
    }
  }

  // Called when the foreground task is destroyed.
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _audio.dispose();
  }

  // Notification button — not used, but must be overridden.
  @override
  void onNotificationButtonPressed(String id) {}
}

// ─── UI-side Service Helper ───────────────────────────────────────────────────

class NavigationForegroundService {
  NavigationForegroundService._();

  // ── Configuration ─────────────────────────────────────────────────────────────
  static void _configure() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'vidur_navigation',
        channelName: 'VIDUR Navigation',
        channelDescription: 'Keeps VIDUR navigation running in the background',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        // foreground service type: MICROPHONE (manually removed due to enum ambiguity, check manifest)
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000), // 1 s tick
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Starts the foreground service with the VIDUR navigation notification.
  static Future<ServiceRequestResult> startService() async {
    _configure();
    return FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'VIDUR',
      notificationText: 'Guidance active',
      callback: startNavigationCallback,
    );
  }

  /// Stops the foreground service.
  static Future<ServiceRequestResult> stopService() {
    return FlutterForegroundTask.stopService();
  }

  /// Sends the current instruction text to the background TaskHandler,
  /// which will speak it via AudioService and update the notification.
  static void updateInstruction(String spokenText) {
    FlutterForegroundTask.sendDataToTask(spokenText);
  }
}
