// lib/core/providers.dart — Person 1 owns this file.
// Riverpod providers for shared engine abstractions.
// Import alongside contracts.dart — same cross-module rules apply.

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
