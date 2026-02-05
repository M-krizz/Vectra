import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_colors.dart';
import 'providers/registration_providers.dart';
import 'widgets/active_eco_background.dart';

/// Futuristic HUD-style driver verification screen
class VerificationHUD extends ConsumerStatefulWidget {
  const VerificationHUD({super.key});

  @override
  ConsumerState<VerificationHUD> createState() => _VerificationHUDState();
}

class _VerificationHUDState extends ConsumerState<VerificationHUD>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Simulate verification progress
    _simulateVerification();
  }

  Future<void> _simulateVerification() async {
    // Initial delay for "Initializing..."
    await Future.delayed(const Duration(seconds: 1));
    ref.read(verificationStatusProvider.notifier).state =
        VerificationStatus.scanning;

    // Simulate scanning for a brief period
    await Future.delayed(const Duration(seconds: 4));
    ref.read(verificationStatusProvider.notifier).state =
        VerificationStatus.completed;
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(verificationStatusProvider);

    return Scaffold(
      body: Stack(
        children: [
          const ActiveEcoBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Scanning animation
                    _buildScanningCircle(),

                    const SizedBox(height: 60),

                    // Status title
                    Text(
                      _getStatusTitle(status),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: AppColors.hyperLime.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 600.ms),

                    const SizedBox(height: 60),

                    // Complete button (shown when done)
                    if (status == VerificationStatus.completed)
                      _buildCompleteButton(context)
                          .animate()
                          .fadeIn(delay: 500.ms)
                          .scale(curve: Curves.elasticOut),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningCircle() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Container(
                width: 200 + 20 * sin(_scanController.value * 2 * pi),
                height: 200 + 20 * sin(_scanController.value * 2 * pi),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.hyperLime.withOpacity(
                      0.3 + 0.3 * sin(_scanController.value * 2 * pi),
                    ),
                    width: 3,
                  ),
                ),
              );
            },
          ),

          // Inner circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.carbonGrey.withOpacity(0.5),
              border: Border.all(color: AppColors.hyperLime, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.hyperLime.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 80,
              color: AppColors.hyperLime,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.hyperLime,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.hyperLime.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Text(
          'Complete Setup',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  String _getStatusTitle(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => 'Initializing...',
      VerificationStatus.scanning => 'Scanning Credentials',
      VerificationStatus.identityVerified => 'Identity Verified',
      VerificationStatus.documentsProcessing => 'Processing Documents',
      VerificationStatus.backgroundCheckPending => 'Final Checks',
      VerificationStatus.completed => 'Verification Complete!',
    };
  }
}

/// Custom painter for scanning grid effect
class ScanGridPainter extends CustomPainter {
  final Animation<double> animation;

  ScanGridPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hyperLime.withOpacity(0.1)
      ..strokeWidth = 1;

    const gridSpacing = 40.0;
    final offset = animation.value * gridSpacing;

    // Vertical lines
    for (double x = -gridSpacing + offset; x < size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = -gridSpacing + offset; y < size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ScanGridPainter oldDelegate) => true;
}
