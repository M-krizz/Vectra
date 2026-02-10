import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Turquoise Theme
  static const Color primary = Color(0xFF4DBFB8);
  static const Color primaryDark = Color(0xFF3AA39D);
  static const Color primaryLight = Color(0xFF6DD4CE);

  // Background Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);

  // Accent Colors
  static const Color success = Color(0xFF48BB78);
  static const Color error = Color(0xFFF56565);
  static const Color warning = Color(0xFFED8936);
  static const Color info = Color(0xFF4299E1);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFFE2E8F0);
  static const Color greyDark = Color(0xFFCBD5E0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
