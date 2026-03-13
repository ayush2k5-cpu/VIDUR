import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'session_repository_impl.dart';
import 'watch_home_screen.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String _pin = '';
  String? _error;
  bool _isLoading = false;
  int _shakeKey = 0;

  static const Color backgroundColor = Color(0xFF0C0C0E);
  static const Color textColor = Color(0xFFF0ECE4);
  static const Color watchGold = Color(0xFFC8A850);

  void _onNumberPressed(int number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number.toString();
        _error = null;
      });
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
    }
  }

  Future<void> _onJoinPressed() async {
    if (_pin.length < 4 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref.read(sessionRepositoryProvider).joinSession(_pin);
      
      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => WatchHomeScreen(pin: _pin)),
        );
      } else {
        _triggerError("PIN not found");
      }
    } catch (e) {
      _triggerError("PIN not found");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _triggerError(String msg) {
    setState(() {
      _error = msg;
      _pin = '';
      _shakeKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Enter PIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 48),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isEntered = index < _pin.length;
                  final isError = _error != null;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    width: 60,
                    height: 72,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isError 
                            ? Colors.red 
                            : (isEntered ? watchGold : textColor.withOpacity(0.2)),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isError ? Colors.red.withOpacity(0.1) : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isEntered ? _pin[index] : '',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                        color: watchGold,
                      ),
                    ),
                  );
                }),
              ).animate(key: ValueKey(_shakeKey), autoPlay: _shakeKey > 0)
                .shake(hz: 8, curve: Curves.easeInOutCubic, duration: 400.ms),

              const SizedBox(height: 24),
              SizedBox(
                height: 24,
                child: Center(
                  child: _error != null
                      ? Text(
                          _error!,
                          semanticsLabel: "Error: $_error",
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              const Spacer(),

              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (int i = 1; i <= 9; i++) _buildNumberButton(i),
                  const SizedBox.shrink(),
                  _buildNumberButton(0),
                  _buildDeleteButton(),
                ],
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _pin.length == 4 && !_isLoading ? _onJoinPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: watchGold,
                  disabledBackgroundColor: watchGold.withOpacity(0.3),
                  foregroundColor: backgroundColor,
                  disabledForegroundColor: backgroundColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          valueColor: AlwaysStoppedAnimation<Color>(backgroundColor)
                        )
                      )
                    : const Text(
                        'Join',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return OutlinedButton(
      onPressed: () => _onNumberPressed(number),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: watchGold, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        number.toString(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      onPressed: _onDeletePressed,
      icon: const Icon(Icons.backspace_outlined, color: textColor, size: 24),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}
