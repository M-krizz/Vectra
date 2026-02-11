import 'package:flutter/material.dart';

/// Vectra Commercial Color Palette
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const voidBlack = Color(0xFF080808);
  static const deepBlack = Color(0xFF0A0A0A); // Added for screens
  static const hyperLime = Color(0xFFCCFF00);
  static const carbonGrey = Color(0xFF1F1F1F);
  
  // Accent Colors
  static const neonGreen = Color(0xFF00FF00);
  static const deepGreen = Color(0xFF003300);
  static const skyBlue = Color(0xFF4A90E2); // Added for UI elements
  
  // Semantic Colors
  static const errorRed = Color(0xFFFF3B30);
  static const successGreen = Color(0xFF34C759);
  static const warningOrange = Color(0xFFFF9500);
  static const warningAmber = Color(0xFFF59E0B); // Added for incentives
  
  // Opacity Variants
  static final white10 = Colors.white.withOpacity(0.1);
  static final white20 = Colors.white.withOpacity(0.2);
  static final white30 = Colors.white.withOpacity(0.3);
  static final white50 = Colors.white.withOpacity(0.5);
  static final white70 = Colors.white.withOpacity(0.7);
  static final black50 = Colors.black.withOpacity(0.5);
  
  // Gradients
  static const heroGradient = LinearGradient(
    colors: [hyperLime, voidBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const backgroundGradient = RadialGradient(
    colors: [Color(0x2200FF00), voidBlack],
    radius: 1.4,
  );
}
