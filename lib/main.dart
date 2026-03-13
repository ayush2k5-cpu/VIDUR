import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'package:vidur/companion/session_repository_impl.dart' hide sessionRepositoryProvider;
import 'package:vidur/core/providers.dart';
import 'package:vidur/theme/theme.dart';
import 'package:vidur/components/splash_screen.dart';
import 'package:vidur/components/mode_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // runApp immediately so Flutter signals Android the first frame is ready.
  // Firebase initializes inside FutureBuilder — avoids Android 15 white screen.
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<void> _init;

  @override
  void initState() {
    super.initState();
    _init = _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) rethrow;
      // Already initialized — safe to continue.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0C0C0E),
              body: Center(
                child: Text(
                  'Init error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          // Show dark screen immediately — this signals Android the first frame is ready.
          return const MaterialApp(
            home: Scaffold(backgroundColor: Color(0xFF0C0C0E)),
          );
        }
        return ProviderScope(
          overrides: [
            sessionRepositoryProvider.overrideWithValue(SessionRepositoryImpl()),
          ],
          child: const VidurApp(),
        );
      },
    );
  }
}

class VidurApp extends StatelessWidget {
  const VidurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIDUR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.appTheme,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () => setState(() => _splashDone = true),
      );
    }
    return ModeSelectScreen(
      onNavigatorSelected: () {},
      onCompanionSelected: () {},
    );
  }
}
