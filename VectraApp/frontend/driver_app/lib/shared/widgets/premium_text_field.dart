import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

/// Premium command-palette style text field with glowing borders.
class PremiumTextField extends StatefulWidget {
  final String hint;
  final String? label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool isValid;
  final bool showError;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;

  const PremiumTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.onChanged,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    Color fillColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    Border? border;

    if (_isFocused) {
      border = Border.all(color: accent, width: 1);
    } else if (widget.showError) {
      border = Border.all(color: AppColors.errorRed, width: 1);
    } else if (widget.isValid) {
      border = Border.all(color: AppColors.successGreen.withValues(alpha: 0.5), width: 1);
    }

    final field = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 64,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: border ?? (isDark ? null : Border.all(color: colors.outline.withValues(alpha: 0.2))),
        boxShadow: _isFocused
            ? [BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2)]
            : isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
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
                controller: widget.controller,
                onChanged: widget.onChanged,
                keyboardType: widget.keyboardType,
                style: GoogleFonts.dmSans(
                  color: colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: accent,
                cursorWidth: 2,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.dmSans(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
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

    if (widget.label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label!,
            style: GoogleFonts.dmSans(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          field,
        ],
      );
    }

    return field;
  }
}