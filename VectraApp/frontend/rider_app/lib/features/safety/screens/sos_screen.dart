import 'dart:async';
import 'package:flutter/material.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('\u{1F6A8} SOS sent! Emergency services notified.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final normalBg = colors.surface;
    final normalText = colors.onSurface;

    return Scaffold(
      backgroundColor: _triggered ? colors.error : normalBg,
      appBar: AppBar(
        title: Text('SOS Emergency',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _triggered ? colors.onError : normalText,
            )),
        backgroundColor: _triggered ? colors.error : normalBg,
        iconTheme: IconThemeData(color: _triggered ? colors.onError : normalText),
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
                const Text('\u{1F6A8}', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(
                  'Emergency SOS',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: normalText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the button below to alert emergency services and your emergency contacts with your live location.',
                  style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: _triggerSOS,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: colors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.error.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: colors.onError,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Also contacts: Police (100) \u00B7 Ambulance (108)',
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Transform.scale(
                    scale: 1.0 + _pulseController.value * 0.08,
                    child: const Text('\u{1F6A8}', style: TextStyle(fontSize: 80)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SOS ACTIVATED',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: colors.onError, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sending alert in $_countdown seconds\u2026',
                  style: TextStyle(fontSize: 16, color: colors.onError.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _cancelSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.surface,
                    foregroundColor: colors.error,
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
