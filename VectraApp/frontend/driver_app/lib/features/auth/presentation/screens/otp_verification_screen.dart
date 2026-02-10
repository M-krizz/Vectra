import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../../../shared/widgets/otp_input.dart';
import '../providers/auth_providers.dart';
import '../../../map_home/presentation/screens/driver_dashboard_screen.dart';

/// OTP verification screen — Premium UI
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
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

    final success =
        await ref.read(authProvider.notifier).verifyOtp(_enteredOtp);

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DriverDashboardScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0) return;

    final success = await ref.read(authProvider.notifier).resendOtp();
    if (success) {
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('OTP sent successfully',
                    style: GoogleFonts.dmSans()),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String get _maskedPhone {
    final phone = widget.phoneNumber;
    if (phone.length > 6) {
      return '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '•')}${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      body: Stack(
        children: [
          // Background
          _buildBackground(size),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildHeader(),
                      SizedBox(height: size.height * 0.05),
                      _buildLockIcon(),
                      const SizedBox(height: 36),
                      _buildTitle(),
                      const SizedBox(height: 40),
                      _buildOtpSection(),
                      const SizedBox(height: 16),
                      if (authState.error != null)
                        _buildErrorMessage(authState.error!.message),
                      const SizedBox(height: 32),
                      _buildVerifyButton(authState.isLoading),
                      const SizedBox(height: 28),
                      _buildResendSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        Container(color: AppColors.voidBlack),

        // Amber orb top-right
        Positioned(
          top: -size.height * 0.08,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.hyperLime.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Subtle bottom orb
        Positioned(
          bottom: -size.height * 0.1,
          left: -size.width * 0.2,
          child: Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.neonGreen.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.carbonGrey.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.white10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
        ),
        const Spacer(),
        // Step indicator
        Row(
          children: [
            _buildStepDot(true),
            Container(
              width: 20,
              height: 1.5,
              color: AppColors.hyperLime.withOpacity(0.5),
            ),
            _buildStepDot(true),
          ],
        ),
      ],
    );
  }

  Widget _buildStepDot(bool active) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.hyperLime : AppColors.white10,
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.hyperLime.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildLockIcon() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer static ring
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.hyperLime.withOpacity(0.12),
                width: 1.5,
              ),
            ),
          ),
          // Icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.hyperLime.withOpacity(0.15),
                  AppColors.neonGreen.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.hyperLime.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.hyperLime.withOpacity(0.1),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.hyperLime,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            text: 'Enter the 4-digit code sent to\n',
            style: GoogleFonts.dmSans(
              color: AppColors.white50,
              fontSize: 15,
              height: 1.6,
            ),
            children: [
              TextSpan(
                text: widget.phoneNumber,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.hyperLime,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        children: [
          OtpInput(
            length: 4,
            onChanged: (otp) {
              setState(() {
                _enteredOtp = otp;
              });
            },
            onCompleted: (otp) {
              setState(() {
                _enteredOtp = otp;
              });
              _handleVerify();
            },
          ),
          const SizedBox(height: 16),
          // Hint text
          Text(
            'OTP auto-submits on completion',
            style: GoogleFonts.dmSans(
              color: AppColors.white20,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.errorRed.withOpacity(0.15),
            ),
            child: const Icon(Icons.error_outline,
                color: AppColors.errorRed, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: AppColors.errorRed,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(bool isLoading) {
    final isValid = _enteredOtp.length == 4;

    return GestureDetector(
      onTap: isLoading || !isValid ? null : _handleVerify,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isValid
              ? const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isValid ? null : AppColors.carbonGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: isValid
              ? null
              : Border.all(color: AppColors.white10),
          boxShadow: isValid
              ? [
                  BoxShadow(
                    color: AppColors.hyperLime.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
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
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: isValid
                          ? Colors.black.withOpacity(0.7)
                          : AppColors.white20,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Verify & Continue',
                      style: GoogleFonts.outfit(
                        color: isValid ? Colors.black : AppColors.white30,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: Column(
        children: [
          Text(
            "Didn't receive the code?",
            style: GoogleFonts.dmSans(
              color: AppColors.white30,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _resendSeconds == 0 ? _handleResend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _resendSeconds == 0
                    ? AppColors.hyperLime.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _resendSeconds == 0
                      ? AppColors.hyperLime.withOpacity(0.3)
                      : AppColors.white10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_resendSeconds > 0) ...[
                    // Timer circle
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _resendSeconds / 30,
                            strokeWidth: 2,
                            color: AppColors.white30,
                            backgroundColor: AppColors.white10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Resend in ${_resendSeconds}s',
                      style: GoogleFonts.dmSans(
                        color: AppColors.white30,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.refresh_rounded,
                        color: AppColors.hyperLime, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Resend Code',
                      style: GoogleFonts.dmSans(
                        color: AppColors.hyperLime,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
