import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const voidBlack = Color(0xFF000000); // Pitch black
  static const carbonGrey = Color(0xFF151515);
  static const hyperLime = Color(0xFFCCFF00); // Signature accent
  static const neonGreen = Color(0xFF39FF14);
  static const errorRed = Color(0xFFFF3333);
  static const white10 = Color(0x1AFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const successGreen = Color(0xFF00FF00);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.voidBlack,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.hyperLime,
        secondary: AppColors.carbonGrey,
        surface: AppColors.carbonGrey,
        error: AppColors.errorRed,
        onPrimary: Colors.black,
      ),
      
      // Typography
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.0,
        ),
        bodyLarge: GoogleFonts.dmSans(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500
        ),
        bodyMedium: GoogleFonts.dmSans(
            fontSize: 16, color: AppColors.white70, fontWeight: FontWeight.w500
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.hyperLime)),
        contentPadding: const EdgeInsets.all(20),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.hyperLime,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
