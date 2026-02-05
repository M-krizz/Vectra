import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final bool enabled;
  final int currentStep;
  final int totalSteps;

  const FloatingNavBar({
    super.key,
    required this.enabled,
    this.onNext,
    this.onBack,
    this.currentStep = 0,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.carbonGrey.withOpacity(0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.white10, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                if (onBack != null)
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white70,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 80),

                // Step indicator
                Row(
                  children: List.generate(totalSteps, (index) {
                    final isActive = index == currentStep;
                    final isCompleted = index < currentStep;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCompleted || isActive
                            ? AppColors.hyperLime
                            : AppColors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Next button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          enabled ? AppColors.hyperLime : Colors.grey.shade800,
                      foregroundColor: enabled ? Colors.black : Colors.grey,
                      elevation: enabled ? 8 : 0,
                      shadowColor: enabled
                          ? AppColors.hyperLime.withOpacity(0.5)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: enabled ? onNext : null,
                    child: Row(
                      children: [
                        Text(
                          currentStep == totalSteps - 1 ? 'Verify' : 'Next',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  )
                      .animate(target: enabled ? 1 : 0)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.0, 1.0),
                        duration: 300.ms,
                        curve: Curves.elasticOut,
                      )
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.white.withOpacity(0.3),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

