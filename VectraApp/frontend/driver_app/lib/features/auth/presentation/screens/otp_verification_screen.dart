import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../../../shared/widgets/active_eco_background.dart';
import '../../../../shared/widgets/otp_input.dart';
import '../providers/auth_providers.dart';
import '../../../map_home/presentation/screens/driver_dashboard_screen.dart';

/// OTP verification screen
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _enteredOtp = '';
  int _resendSeconds = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    if (_enteredOtp.length != 4) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(_enteredOtp);

    if (success && mounted) {
      // Navigation is handled by main.dart based on auth state changes
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0) return;

    final success = await ref.read(authProvider.notifier).resendOtp();
    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP sent successfully',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          const ActiveEcoBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildTitle(),
                  const SizedBox(height: 48),
                  _buildOtpInput(),
                  const SizedBox(height: 16),
                  if (authState.error != null) _buildErrorMessage(authState.error!.message),
                  const SizedBox(height: 32),
                  _buildVerifyButton(authState.isLoading),
                  const SizedBox(height: 24),
                  _buildResendButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.white10,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        Text(
          'Code',
          style: GoogleFonts.outfit(
            color: AppColors.hyperLime,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            text: 'Enter the 4-digit code sent to ',
            style: GoogleFonts.dmSans(
              color: AppColors.white70,
              fontSize: 16,
            ),
            children: [
              TextSpan(
                text: widget.phoneNumber,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildOtpInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
      ),
      child: OtpInput(
        length: 4,
        onCompleted: (otp) {
          setState(() {
            _enteredOtp = otp;
          });
          _handleVerify();
        },
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: AppColors.errorRed,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().shake();
  }

  Widget _buildVerifyButton(bool isLoading) {
    final isValid = _enteredOtp.length == 4;

    return GestureDetector(
      onTap: isLoading || !isValid ? null : _handleVerify,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isValid
              ? const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                )
              : null,
          color: isValid ? null : AppColors.white10,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isValid
              ? [
                  BoxShadow(
                    color: AppColors.hyperLime.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(
                  'Verify & Continue',
                  style: GoogleFonts.dmSans(
                    color: isValid ? Colors.black : AppColors.white50,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildResendButton() {
    return Center(
      child: GestureDetector(
        onTap: _resendSeconds == 0 ? _handleResend : null,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: GoogleFonts.dmSans(
            color: _resendSeconds == 0 ? AppColors.hyperLime : AppColors.white50,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          child: Text(
            _resendSeconds > 0
                ? 'Resend code in ${_resendSeconds}s'
                : 'Resend code',
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms);
  }
}
