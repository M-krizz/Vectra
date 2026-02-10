import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'signup_stages/basic_details_screen.dart';
import '../utils/notification_overlay.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendTimer--);
        if (_resendTimer == 0) {
          setState(() => _canResend = true);
          return false;
        }
        return true;
      }
      return false;
    });
  }

  void _verifyOTP() async {
    String otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      NotificationOverlay.showMessage(
        context,
        'Please enter complete OTP',
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      // Navigate directly to basic details screen for new user sign up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BasicDetailsScreen(phoneNumber: widget.phoneNumber),
        ),
      );
    }
  }

  void _resendOTP() async {
    if (!_canResend) return;

    // Simulate API call
    NotificationOverlay.showMessage(
      context,
      'OTP sent successfully!',
      backgroundColor: AppColors.success,
    );

    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Header
                      const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter the 6-digit code sent to\n+91 ${widget.phoneNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // OTP Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 50,
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }

                                // Auto-verify when all fields are filled
                                if (index == 5 && value.isNotEmpty) {
                                  _verifyOTP();
                                }
                              },
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 32),

                      // Resend OTP
                      Center(
                        child: TextButton(
                          onPressed: _canResend ? _resendOTP : null,
                          child: Text(
                            _canResend
                                ? 'Resend OTP'
                                : 'Resend OTP in $_resendTimer seconds',
                            style: TextStyle(
                              color: _canResend
                                  ? AppColors.primary
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary
                                .withValues(alpha: 0.6),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Verify & Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
