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
        // Check if all filled
        final otp = _controllers.map((c) => c.text).join();
        if (otp.length == widget.length) {
          widget.onCompleted(otp);
        }
      }
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return _buildOtpBox(index);
      }),
    );
  }

  Widget _buildOtpBox(int index) {
    final hasFocus = _hasFocus[index];
    final hasValue = _controllers[index].text.isNotEmpty;
    final width = MediaQuery.of(context).size.width;
    // Responsive width: 15% of screen, capped between 45 and 60
    final boxWidth = (width * 0.15).clamp(45.0, 60.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: boxWidth,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.voidBlack,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFocus
              ? AppColors.hyperLime
              : hasValue
                  ? AppColors.successGreen
                  : AppColors.white10,
          width: 2,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: AppColors.hyperLime.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 0,
                ),
              ]
            : hasValue
                ? [
                    BoxShadow(
                      color: AppColors.successGreen.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: AppColors.hyperLime,
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
