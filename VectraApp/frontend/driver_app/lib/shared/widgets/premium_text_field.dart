import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Premium command-palette style text field with glowing borders
class PremiumTextField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isValid;
  final bool showError;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;

  const PremiumTextField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.isValid = false,
    this.showError = false,
    this.keyboardType,
    this.prefixIcon,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // Commercial Input Style
    Color fillColor = const Color(0xFF1A1A1A);
    Border? border; // No border by default
    
    if (_isFocused) {
      border = Border.all(color: AppColors.hyperLime, width: 1); // Thin Lime Green border
    } else if (widget.showError) {
      border = Border.all(color: AppColors.errorRed, width: 1);
    } else if (widget.isValid) {
      border = Border.all(color: AppColors.successGreen.withOpacity(0.5), width: 1);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 64, // Explicit height for robustness
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: border,
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.hyperLime.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            widget.prefixIcon!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Focus(
              onFocusChange: (focused) {
                setState(() => _isFocused = focused);
              },
              child: TextField(
                onChanged: widget.onChanged,
                keyboardType: widget.keyboardType,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: AppColors.hyperLime,
                cursorWidth: 2,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          if (widget.isValid)
            const Icon(
              Icons.check_circle,
              color: AppColors.successGreen,
              size: 20,
            ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}
