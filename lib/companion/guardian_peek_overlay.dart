import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// Since this is a demo, we use a placeholder App ID.
// In a real scenario, this comes from a secure backend.
const String _agoraAppId = '68d3e5cc476148aa8fc35138f6a69bc9'; // Real Agora App ID

class GuardianPeekOverlay extends StatefulWidget {
  final String channelId;
  final VoidCallback onClose;

  const GuardianPeekOverlay({
    super.key,
    required this.channelId,
    required this.onClose,
  });

  @override
  State<GuardianPeekOverlay> createState() => _GuardianPeekOverlayState();
}

class _GuardianPeekOverlayState extends State<GuardianPeekOverlay> {
  RtcEngine? _engine;
  bool _joined = false;
  int? _remoteUid;
  int _secondsLeft = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _closeAndDispose();
        }
      });
    });
  }

  Future<void> _initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: _agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Local user uid:${connection.localUid} joined the channel");
            if (mounted) setState(() => _joined = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("Remote user uid:$remoteUid joined the channel");
            if (mounted) setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint("Remote user uid:$remoteUid left the channel");
            if (mounted) setState(() => _remoteUid = null);
          },
        ),
      );

      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
      await _engine!.enableVideo();

      await _engine!.joinChannel(
        token: '', // Using empty token for demo purposes (requires App ID without cert)
        channelId: widget.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          clientRoleType: ClientRoleType.clientRoleAudience,
        ),
      );
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
    }
  }

  void _closeAndDispose() {
    _cleanup();
    widget.onClose();
  }

  Future<void> _cleanup() async {
    _countdownTimer?.cancel();
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam, color: Color(0xFFC8A850)),
                      const SizedBox(width: 8),
                      const Text(
                        'GUARDIAN PEEK',
                        style: TextStyle(
                          color: Color(0xFFC8A850),
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _secondsLeft < 10 ? Colors.red.withOpacity(0.2) : const Color(0xFFC8A850).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _secondsLeft < 10 ? Colors.red : const Color(0xFFC8A850),
                      ),
                    ),
                    child: Text(
                      '00:${_secondsLeft.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _secondsLeft < 10 ? Colors.red : const Color(0xFFC8A850),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0C0E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC8A850).withOpacity(0.3), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildVideoView(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _closeAndDispose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A020),
                  foregroundColor: const Color(0xFF0C0C0E),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'END PEEK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    if (!_joined) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFC8A850)),
            SizedBox(height: 16),
            Text(
              'Connecting to Navigator...',
              style: TextStyle(color: Color(0xFFF0ECE4), fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }
    
    // In a real scenario, this would determine if it's the sender or receiver
    // Right now, both try to publish and subscribe. We show the remote video if available,
    // otherwise the local preview (so the navigator sees themselves, debugging essentially).
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    } else {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }
  }
}
