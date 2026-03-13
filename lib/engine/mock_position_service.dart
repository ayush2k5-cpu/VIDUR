// lib/engine/mock_position_service.dart — Person 1 owns this file.
// Stub — implement on branch/engine.

import '../core/contracts.dart';

class MockPositionService implements PositionStream {
  @override
  Stream<VidurPosition> get positionUpdates => const Stream.empty();

  @override
  Future<void> initialize(VenueMap venue) async {}
}
