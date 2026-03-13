import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:vidur/theme/theme.dart';
import 'package:vidur/components/splash_screen.dart';
import 'package:vidur/components/mode_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: VidurApp()));
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
      // TODO: wire to actual navigator/companion screen routes
      onNavigatorSelected: () {},
      onCompanionSelected: () {},
    );
  }
}
