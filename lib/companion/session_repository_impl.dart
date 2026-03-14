import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/contracts.dart';

// Single shared instance — PIN survives across Navigator screen pushes.
// Public so main.dart can wire it via ProviderScope.overrides.
final sharedRepo = SessionRepositoryImpl._internal();

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return sharedRepo;
});

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref('sessions/');
  String? _pin;

  /// Exposed so that QrScannerScreen / createSession can stamp the PIN once.
  void setPin(String pin) {
    _pin = pin;
    debugPrint('[SessionRepo] PIN set to $_pin');
  }

  @override
  Future<String> createSession(String venueId) async {
    final pin = (Random().nextInt(9000) + 1000).toString();
    setPin(pin);
    await _db.child(pin).set({
      'venueId': venueId,
      'createdAt': ServerValue.timestamp,
    });
    return pin;
  }

  @override
  Future<bool> joinSession(String pin) async {
    final snapshot = await _db.child(pin).get();
    if (snapshot.exists) {
      setPin(pin);
      await _db.child(pin).update({
        'companionId': 'companion_${Random().nextInt(10000)}',
      });
      return true;
    }
    return false;
  }

  @override
  Stream<SessionState> get sessionUpdates {
    if (_pin == null) {
      debugPrint('[SessionRepo] sessionUpdates: _pin is null, returning empty stream');
      return const Stream.empty();
    }
    debugPrint('[SessionRepo] Subscribing to Firebase at sessions/$_pin');
    return _db.child(_pin!).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

      OrbState state = OrbState.safe;
      final orbStateRaw = data['orbState'] as String?;
      if (orbStateRaw == 'help') state = OrbState.help;
      if (orbStateRaw == 'arrived') state = OrbState.arrived;
      if (orbStateRaw == 'paused') state = OrbState.paused;

      final posRaw = data['currentPosition'] as Map<dynamic, dynamic>?;
      VidurPosition? pos;
      if (posRaw != null) {
        pos = VidurPosition(
          x: (posRaw['x'] as num?)?.toDouble() ?? 0.0,
          y: (posRaw['y'] as num?)?.toDouble() ?? 0.0,
          floor: (posRaw['floor'] as num?)?.toInt() ?? 0,
          confidence: (posRaw['confidence'] as num?)?.toDouble() ?? 0.0,
        );
      }

      final peekRaw = data['peekRequest'] as Map<dynamic, dynamic>?;
      PeekState? peekState;
      if (peekRaw != null) {
        final reqBy = peekRaw['requestedBy'] as String?;
        PeekRequester? requester;
        if (reqBy == 'companion') requester = PeekRequester.companion;
        if (reqBy == 'navigator') requester = PeekRequester.navigator;

        peekState = PeekState(
          active: peekRaw['active'] == true,
          requestedBy: requester,
          agoraChannel: peekRaw['agoraChannel'] as String?,
        );
        debugPrint('[SessionRepo] peekState: active=${peekState.active} channel=${peekState.agoraChannel}');
      }

      return SessionState(
        orbState: state,
        position: pos,
        peekState: peekState,
        lastMovement: DateTime.now(),
      );
    });
  }

  @override
  Future<void> updatePosition(VidurPosition position) async {
    if (_pin == null) return;
    await _db.child(_pin!).child('currentPosition').set({
      'x': position.x,
      'y': position.y,
      'floor': position.floor,
      'confidence': position.confidence,
    });
  }

  @override
  Future<void> fireHelp() async {
    if (_pin == null) return;
    final posSnapshot = await _db.child(_pin!).child('currentPosition').get();
    final updates = <String, dynamic>{
      'helpEvent/fired': true,
      'orbState': 'help',
    };
    if (posSnapshot.exists) {
      updates['lastPosition'] = posSnapshot.value;
    }
    await _db.child(_pin!).update(updates);
  }

  @override
  Future<void> fireArrival(SessionStats stats) async {
    if (_pin == null) return;
    await _db.child(_pin!).update({
      'arrivalEvent/arrived': true,
      'orbState': 'arrived',
      'stats': {
        'distanceMeters': stats.distanceMeters,
        'durationMs': stats.duration.inMilliseconds,
        'obstaclesAvoided': stats.obstaclesAvoided,
      }
    });
  }

  @override
  Future<void> requestPeek(PeekRequester requester) async {
    if (_pin == null) return;
    debugPrint('[SessionRepo] requestPeek by ${requester.name} on channel vidur_$_pin');
    await _db.child(_pin!).child('peekRequest').set({
      'active': true,
      'requestedBy': requester.name,
      'agoraChannel': 'vidur_$_pin',
      'startedAt': ServerValue.timestamp,
    });
  }
}
