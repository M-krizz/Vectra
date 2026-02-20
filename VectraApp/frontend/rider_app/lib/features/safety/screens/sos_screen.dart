import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  bool _triggered = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  late AnimationController _pulseController;

  void _triggerSOS() {
    setState(() => _triggered = true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown == 0) {
        t.cancel();
        // Mock: SOS sent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 SOS sent! Emergency services notified.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    });
    _pulseController.repeat();
  }

  void _cancelSOS() {
    _countdownTimer?.cancel();
    setState(() { _triggered = false; _countdown = 5; });
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _triggered ? AppColors.error : Colors.white,
      appBar: AppBar(
        title: Text('SOS Emergency',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _triggered ? Colors.white : AppColors.textPrimary,
            )),
        backgroundColor: _triggered ? AppColors.error : Colors.white,
        iconTheme: IconThemeData(color: _triggered ? Colors.white : AppColors.textPrimary),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _triggered ? _cancelSOS : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_triggered) ...[
                const Text('🚨', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                const Text(
                  'Emergency SOS',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap the button below to alert emergency services and your emergency contacts with your live location.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // SOS Button
                GestureDetector(
                  onTap: _triggerSOS,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                const Text(
                  'Also contacts: Police (100) · Ambulance (108)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + _pulseController.value * 0.08,
                    child: const Text('🚨', style: TextStyle(fontSize: 80)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SOS ACTIVATED',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sending alert in $_countdown seconds…',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _cancelSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(200, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Cancel SOS',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
