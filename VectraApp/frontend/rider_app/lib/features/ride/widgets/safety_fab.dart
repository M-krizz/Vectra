import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../safety/screens/safety_center_screen.dart';

/// Floating SOS / Safety button shown during active ride phases
class SafetyFab extends StatelessWidget {
  const SafetyFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SafetyCenterScreen()),
        );
      },
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.shield_rounded, size: 20),
      label: const Text(
        'Safety',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
