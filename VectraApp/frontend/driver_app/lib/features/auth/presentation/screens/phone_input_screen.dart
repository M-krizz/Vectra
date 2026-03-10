import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../providers/auth_providers.dart';
import 'otp_verification_screen.dart';

/// Phone input screen for driver authentication
class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final FocusNode _identifierFocusNode = FocusNode();
  bool _isInputValid = false;
  bool _isEmailInput = false;
  bool _isSubmitting = false;
  String _selectedCountryCode = '+91';

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _identifierFocusNode.dispose();
    super.dispose();
  }

  bool _isEmail(String value) => value.contains('@');

  void _validateInput() {
    final raw = _identifierController.text.trim();
    final isEmail = _isEmail(raw);
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final validPhone = digits.length >= 7;
    final validEmail = isEmail && raw.contains('.');
    setState(() {
      _isEmailInput = isEmail;
      _isInputValid = isEmail ? validEmail : validPhone;
    });
  }

  Future<void> _handleContinue() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    _isSubmitting = true;

    String identifier = _identifierController.text.trim();
    String channel = 'phone';

    if (_isEmail(identifier)) {
      channel = 'email';
    } else {
      identifier = identifier.replaceAll(RegExp(r'[\s\-]'), '');
      if (!identifier.startsWith('+')) {
        identifier = '$_selectedCountryCode$identifier';
      }
    }

    try {
      final success = await ref.read(authProvider.notifier).sendOtp(identifier, channel: channel);

      if (success && mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                OtpVerificationScreen(identifier: identifier),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } finally {
      if (mounted) _isSubmitting = false;
    }
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors, isDark),
                const SizedBox(height: 48),
                _buildTitle(colors, isDark),
                const SizedBox(height: 48),
                _buildIdentifierInput(colors, isDark),
                const SizedBox(height: 16),
                if (authState.error != null) _buildErrorMessage(authState.error!.message),
                const SizedBox(height: 32),
                _buildContinueButton(authState.isLoading, colors, isDark),
                const SizedBox(height: 24),
                _buildTermsText(colors, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, bool isDark) {
    final canPop = Navigator.of(context).canPop();
    return Row(
      children: [
        if (canPop)
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
            boxShadow: isDark
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drive_eta, color: isDark ? AppColors.hyperLime : colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Driver App',
                style: GoogleFonts.dmSans(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your',
          style: GoogleFonts.outfit(
            color: colors.onSurface,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        Text(
          'phone or email',
          style: GoogleFonts.outfit(
            color: isDark ? AppColors.hyperLime : colors.primary,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ll send you a verification code',
          style: GoogleFonts.dmSans(
            color: colors.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentifierInput(ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _identifierFocusNode.hasFocus ? accent : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          width: 2,
        ),
        boxShadow: _identifierFocusNode.hasFocus
            ? [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 0)]
            : isDark
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          if (!_isEmailInput) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                underline: const SizedBox(),
                dropdownColor: isDark ? AppColors.carbonGrey : Colors.white,
                icon: Icon(Icons.keyboard_arrow_down, color: colors.onSurfaceVariant),
                style: GoogleFonts.dmSans(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  DropdownMenuItem(value: '+91', child: Text('+91')),
                  DropdownMenuItem(value: '+1', child: Text('+1')),
                  DropdownMenuItem(value: '+44', child: Text('+44')),
                  DropdownMenuItem(value: '+61', child: Text('+61')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCountryCode = value ?? '+91';
                  });
                },
              ),
            ),
            Container(width: 1, height: 40, color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          ],
          Expanded(
            child: TextFormField(
              controller: _identifierController,
              focusNode: _identifierFocusNode,
              keyboardType: _isEmailInput ? TextInputType.emailAddress : TextInputType.phone,
              style: GoogleFonts.dmSans(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: _isEmailInput ? 'you@email.com' : '00000 00000',
                hintStyle: GoogleFonts.dmSans(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 20,
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              inputFormatters: [
                if (!_isEmailInput) FilteringTextInputFormatter.digitsOnly,
                if (!_isEmailInput) LengthLimitingTextInputFormatter(10),
                if (!_isEmailInput) _PhoneInputFormatter(),
              ],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Enter phone number or email';
                if (_isEmail(v)) {
                  return v.contains('.') ? null : 'Enter a valid email';
                }
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 7) return 'Enter a valid phone number';
                return null;
              },
              onChanged: (_) => _validateInput(),
            ),
          ),
          if (_isInputValid)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle, color: AppColors.successGreen, size: 24),
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

  Widget _buildContinueButton(bool isLoading, ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return GestureDetector(
      onTap: isLoading || !_isInputValid ? null : _handleContinue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: _isInputValid
              ? LinearGradient(
                  colors: isDark
                      ? [AppColors.hyperLime, AppColors.neonGreen]
                      : [colors.primary, colors.primary.withValues(alpha: 0.8)],
                )
              : null,
          color: _isInputValid ? null : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isInputValid
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
                  'Continue',
                  style: GoogleFonts.dmSans(
                    color: _isInputValid
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

  Widget _buildTermsText(ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return Center(
      child: Text.rich(
        TextSpan(
          text: 'By continuing, you agree to our ',
          style: GoogleFonts.dmSans(color: colors.onSurfaceVariant, fontSize: 12),
          children: [
            TextSpan(
              text: 'Terms of Service',
              style: GoogleFonts.dmSans(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: GoogleFonts.dmSans(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Phone number formatter (00000 00000)
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    if (text.length <= 5) {
      return newValue.copyWith(text: text);
    }
    final formatted = '${text.substring(0, 5)} ${text.substring(5)}';
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}