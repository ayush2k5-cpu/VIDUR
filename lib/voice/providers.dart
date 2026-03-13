// lib/voice/providers.dart
// Riverpod providers scoped to the voice/navigate module.
// sessionRepositoryProvider lives in lib/core/providers.dart — use that.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores the active session PIN after QrScannerScreen creates a session.
/// Read by NavigateMainScreen to write Firebase obstacle events.
/// Reset to null when a session ends.
final currentSessionPinProvider = StateProvider<String?>((ref) => null);
