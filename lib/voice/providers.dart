// lib/voice/providers.dart
// Riverpod providers scoped to the voice/navigate module.
// The sessionRepositoryProvider must be overridden in ProviderScope
// (typically in main.dart) with the real SessionRepositoryImpl.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidur/core/contracts.dart';

/// Override this in ProviderScope with a real SessionRepositoryImpl.
/// Example:
///   ProviderScope(
///     overrides: [
///       sessionRepositoryProvider.overrideWithValue(SessionRepositoryImpl()),
///     ],
///     child: MyApp(),
///   )
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  throw UnimplementedError(
    'sessionRepositoryProvider must be overridden in ProviderScope. '
    'Wire the real SessionRepositoryImpl from lib/companion/.',
  );
});

/// Stores the active session PIN after QrScannerScreen creates a session.
/// Read by NavigateMainScreen to write Firebase obstacle events.
/// Reset to null when a session ends.
final currentSessionPinProvider = StateProvider<String?>((ref) => null);
