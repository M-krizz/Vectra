import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';

/// Neon-glowing OTP input with auto-focus management
class OtpInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final int length;

  const OtpInput({
    super.key,
    required this.onCompleted,
    this.length = 4,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<bool> _hasFocus;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _hasFocus = List.generate(widget.length, (_) => false);

    for (int i = 0; i < widget.length; i++) {
      _focusNodes[i].addListener(() {
        setState(() {
          _hasFocus[i] = _focusNodes[i].hasFocus;
        });
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final otp = _controllers.map((c) => c.text).join();
        if (otp.length == widget.length) {
          widget.onCompleted(otp);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final spacing = 8.0;
        final totalSpacing = spacing * (widget.length - 1);
        final boxWidth = ((availableWidth - totalSpacing) / widget.length).clamp(40.0, 60.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            return Padding(
              padding: EdgeInsets.only(left: index > 0 ? spacing : 0),
              child: _buildOtpBox(index, boxWidth),
            );
          }),
        );
      },
    );
  }

  Widget _buildOtpBox(int index, double boxWidth) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    final hasFocus = _hasFocus[index];
    final hasValue = _controllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: boxWidth,
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? AppColors.voidBlack : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFocus
              ? accent
              : hasValue
                  ? AppColors.successGreen
                  : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          width: 2,
        ),
        boxShadow: hasFocus
            ? [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 25, spreadRadius: 0)]
            : hasValue
              ? [BoxShadow(color: AppColors.successGreen.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 0)]
              : isDark
                ? []
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: accent,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) => _onChanged(index, value),
          onTap: () {
            if (_controllers[index].text.isNotEmpty) {
              _controllers[index].clear();
            }
          },
        ),
      ),
    ).animate(target: hasFocus ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }
}