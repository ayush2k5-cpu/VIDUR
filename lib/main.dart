import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      theme: ThemeData(scaffoldBackgroundColor: Color(0xFF0C0C0E)),
      // TODO Person 4: Replace with full theme + router
      home: const Scaffold(
        body: Center(
          child: Text('VIDUR', style: TextStyle(color: Color(0xFFE8A020), fontSize: 40)),
        ),
      ),
    );
  }
}
