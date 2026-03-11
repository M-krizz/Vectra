import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../../../shared/widgets/otp_input.dart';
import '../providers/auth_providers.dart';

/// OTP verification screen
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String identifier;

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _enteredOtp = '';
  int _resendSeconds = 30;
  Timer? _resendTimer;
  bool _isVerifying = false;

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
    if (_enteredOtp.length != 6 || _isVerifying) return;
    setState(() { _isVerifying = true; });

    try {
      final success = await ref.read(authProvider.notifier).verifyOtp(_enteredOtp);

      if (success && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() { _isVerifying = false; });
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
            content: Text('OTP sent successfully', style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _useDebugOtp(String otp) async {
    await Clipboard.setData(ClipboardData(text: otp));
    if (!mounted) return;
    ref.read(authProvider.notifier).clearError();
    setState(() {
      _enteredOtp = otp;
    });
    await _handleVerify();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colors, isDark),
              const SizedBox(height: 48),
              _buildTitle(colors, isDark),
              const SizedBox(height: 48),
              if (authState.debugOtp != null) ...[
                _buildDebugOtpCard(authState.debugOtp!, colors, isDark),
                const SizedBox(height: 20),
              ],
              _buildOtpInput(colors, isDark),
              const SizedBox(height: 16),
              if (authState.error != null) _buildErrorMessage(authState.error!.message),
              const SizedBox(height: 32),
              _buildVerifyButton(authState.isLoading, colors, isDark),
              const SizedBox(height: 24),
              _buildResendButton(colors, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, bool isDark) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification',
          style: GoogleFonts.outfit(
            color: colors.onSurface,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        Text(
          'Code',
          style: GoogleFonts.outfit(
            color: accent,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            text: 'Enter the 6-digit code sent to ',
            style: GoogleFonts.dmSans(
              color: colors.onSurfaceVariant,
              fontSize: 16,
            ),
            children: [
              TextSpan(
                text: widget.identifier,
                style: GoogleFonts.dmSans(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput(ColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: OtpInput(
        length: 6,
        onCompleted: (otp) {
          ref.read(authProvider.notifier).clearError();
          setState(() {
            _enteredOtp = otp;
          });
        },
      ),
    );
  }

  Widget _buildDebugOtpCard(String otp, ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Development OTP',
            style: GoogleFonts.dmSans(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            otp,
            style: GoogleFonts.outfit(
              color: accent,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isVerifying ? null : () => _useDebugOtp(otp),
            child: Text(
              'Use development OTP',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(color: AppColors.errorRed, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(bool isLoading, ColorScheme colors, bool isDark) {
    final isValid = _enteredOtp.length == 6;
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return GestureDetector(
      onTap: isLoading || !isValid || _isVerifying ? null : _handleVerify,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isValid
              ? LinearGradient(
                  colors: isDark
                      ? [AppColors.hyperLime, AppColors.neonGreen]
                      : [colors.primary, colors.primary.withValues(alpha: 0.8)],
                )
              : null,
          color: isValid ? null : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isValid
              ? [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white),
                )
              : Text(
                  'Verify & Continue',
                  style: GoogleFonts.dmSans(
                    color: isValid
                        ? (isDark ? Colors.black : Colors.white)
                        : colors.onSurfaceVariant,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResendButton(ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Center(
      child: GestureDetector(
        onTap: _resendSeconds == 0 ? _handleResend : null,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: GoogleFonts.dmSans(
            color: _resendSeconds == 0 ? accent : colors.onSurfaceVariant,
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
    );
  }
}