import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/contracts.dart';
import 'session_repository_impl.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  StreamSubscription<SessionState>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(sessionRepositoryProvider);
      _subscription = repo.sessionUpdates.listen((session) {
        if (session.orbState == OrbState.safe) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _callNavigator() async {
    final Uri url = Uri(scheme: 'tel', path: '+1234567890');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(sessionRepositoryProvider);

    return Scaffold(
      body: StreamBuilder<SessionState>(
        stream: repo.sessionUpdates,
        builder: (context, snapshot) {
          final pos = snapshot.data?.position;
          final waypointLabel = pos != null ? 'Floor ${pos.floor}' : 'Unknown';
          const navigatorName = 'Caregiver';

          return Stack(
            children: [
              Container()
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .custom(
                    duration: 1.seconds,
                    builder: (context, value, child) {
                      return Container(
                        color: Color.lerp(
                          const Color(0xFFC04040),
                          const Color(0xFF0C0C0E),
                          value,
                        ),
                      );
                    },
                  ),
              
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    const Text(
                      'HELP REQUESTED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        color: Color(0xFFF0ECE4),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Last seen: Area $waypointLabel',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFFF0ECE4),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    const Text(
                      'Waiting for response...',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF706860),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC04040),
                          foregroundColor: const Color(0xFFF0ECE4),
                          minimumSize: const Size.fromHeight(64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        onPressed: _callNavigator,
                        icon: const Icon(Icons.phone, size: 28),
                        label: const Text(
                          'Call $navigatorName',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
