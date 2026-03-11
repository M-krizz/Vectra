import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/app_theme.dart';
import '../../../common/widgets/loading_button.dart';
import '../bloc/auth_bloc.dart';

/// OTP verification screen — receives the identifier from the previous screen
class OtpVerificationScreen extends StatefulWidget {
  final String identifier; // phone number or email that received the OTP
  final String? devOtp;    // pre-filled in dev mode from backend response

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    this.devOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onVerify() {
    final otp = _otp;
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the full 6-digit OTP'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(
      AuthVerifyOtpRequested(identifier: widget.identifier, code: otp),
    );
  }

  void _onResend() {
    final isEmail = widget.identifier.contains('@');
    context.read<AuthBloc>().add(
      AuthOtpRequested(
        identifier: widget.identifier,
        channel: isEmail ? 'email' : 'phone',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP resent!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            // Clear OTP on error
            for (var c in _controllers) {
              c.clear();
            }
            _focusNodes.first.requestFocus();
          }
          // Navigation handled by app_router.dart on AuthAuthenticated / AuthOtpVerificationRequired
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter verification code',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit code to\n${widget.identifier}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // 6-digit OTP input row — responsive width
                LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = ((constraints.maxWidth - 5 * 10) / 6).clamp(40.0, 56.0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => SizedBox(
                          width: boxWidth,
                          height: 56,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onChanged(value, index),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Didn't receive it? ",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _onResend,
                        child: const Text('Resend'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return LoadingButton(
                      onPressed: _onVerify,
                      isLoading: state is AuthLoading,
                      text: 'Verify & Continue',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
