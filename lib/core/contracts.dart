// lib/core/contracts.dart — Person 1 owns this file.
// All cross-module imports come here ONLY.

enum OrbState { safe, paused, help, arrived }
enum InstructionType { turn, straight, arrived, obstacle }
enum PeekRequester { navigator, companion }

class VidurPosition {
  final double x, y;
  final int floor;
  final double confidence; // 0.0–1.0
  const VidurPosition({required this.x, required this.y, required this.floor, required this.confidence});
}

class NavigationInstruction {
  final String spokenText;
  final double bearingDegrees;
  final double distanceMeters;
  final InstructionType type;
  const NavigationInstruction({required this.spokenText, required this.bearingDegrees, required this.distanceMeters, required this.type});
}

class PeekState {
  final bool active;
  final PeekRequester? requestedBy;
  final String? agoraChannel;
  const PeekState({required this.active, this.requestedBy, this.agoraChannel});
}

class SessionState {
  final OrbState orbState;
  final VidurPosition? position;
  final String? currentInstruction;
  final PeekState? peekState;
  final DateTime lastMovement;
  const SessionState({required this.orbState, this.position, this.currentInstruction, this.peekState, required this.lastMovement});
}

class SessionStats {
  final double distanceMeters;
  final Duration duration;
  final int obstaclesAvoided;
  const SessionStats({required this.distanceMeters, required this.duration, required this.obstaclesAvoided});
}

abstract class VenueMap {}

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
