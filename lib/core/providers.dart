// lib/core/providers.dart — Person 1 owns this file.
// Riverpod providers for shared engine abstractions.
// Import alongside contracts.dart — same cross-module rules apply.
// SessionRepository stub lives here until Priyanshu's FirebaseSessionRepository
// lands — override in ProviderScope when ready.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contracts.dart';
import '../engine/venue_map.dart';
import '../engine/mock_position_service.dart';
import '../engine/navigation_engine.dart';

/// Loads VenueMap from assets/venue/test_venue.json.
/// Override in ProviderScope to swap venues.
final venueMapProvider = FutureProvider<VenueMap>((ref) async {
  final raw = await rootBundle.loadString('assets/venue/test_venue.json');
  return VenueMapLoader.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Exposes PositionStream (MockPositionService in dev).
/// Swap implementation by overriding this provider in ProviderScope.
final positionStreamProvider = FutureProvider<PositionStream>((ref) async {
  final venue = await ref.watch(venueMapProvider.future);
  final service = MockPositionService();
  await service.initialize(venue);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Exposes NavigationEngine wired to the active PositionStream.
final navigationEngineProvider = FutureProvider<NavigationEngine>((ref) async {
  final venue = await ref.watch(venueMapProvider.future);
  final posStream = await ref.watch(positionStreamProvider.future);
  final engine = VidurNavigationEngine();
  engine.attach(posStream, venue);
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Stub — replaced by Priyanshu via ProviderScope.overrides in branch/companion.
/// Usage: ref.watch(sessionRepositoryProvider)
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return _StubSessionRepository();
});

class _StubSessionRepository implements SessionRepository {
  @override Future<String> createSession(String venueId) => throw UnimplementedError('stub');
  @override Future<bool> joinSession(String pin) => throw UnimplementedError('stub');
  @override Stream<SessionState> get sessionUpdates => throw UnimplementedError('stub');
  @override Future<void> updatePosition(VidurPosition position) => throw UnimplementedError('stub');
  @override Future<void> fireHelp() => throw UnimplementedError('stub');
  @override Future<void> fireArrival(SessionStats stats) => throw UnimplementedError('stub');
  @override Future<void> requestPeek(PeekRequester requester) => throw UnimplementedError('stub');
}
