import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../../../../shared/widgets/active_eco_background.dart';
import '../providers/auth_providers.dart';
import 'otp_verification_screen.dart';

/// Phone input screen for driver authentication
class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isPhoneValid = false;
  String _selectedCountryCode = '+91';

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _isPhoneValid = phone.length == 10;
    });
  }

  Future<void> _handleContinue() async {
    if (!_isPhoneValid) return;

    print('Handle Continue Clicked');
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final fullPhone = '$_selectedCountryCode$phone';
    print('Phone: $fullPhone');

    final success = await ref.read(authProvider.notifier).sendOtp(phone);
    print('Send OTP result: $success');

    if (success && mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OtpVerificationScreen(phoneNumber: fullPhone),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
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
                  _buildPhoneInput(),
                  const SizedBox(height: 16),
                  if (authState.error != null) _buildErrorMessage(authState.error!.message),
                  const SizedBox(height: 32),
                  _buildContinueButton(authState.isLoading),
                  const SizedBox(height: 24),
                  _buildTermsText(),
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
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.carbonGrey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drive_eta, color: AppColors.hyperLime, size: 20),
              const SizedBox(width: 8),
              Text(
                'Driver App',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
          'Enter your',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        Text(
          'phone number',
          style: GoogleFonts.outfit(
            color: AppColors.hyperLime,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ll send you a verification code',
          style: GoogleFonts.dmSans(
            color: AppColors.white70,
            fontSize: 16,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildPhoneInput() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _phoneFocusNode.hasFocus ? AppColors.hyperLime : AppColors.white10,
          width: 2,
        ),
        boxShadow: _phoneFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.hyperLime.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Country code dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              underline: const SizedBox(),
              dropdownColor: AppColors.carbonGrey,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.white70),
              style: GoogleFonts.dmSans(
                color: Colors.white,
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
          Container(width: 1, height: 40, color: AppColors.white10),
          // Phone input
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: '00000 00000',
                hintStyle: GoogleFonts.dmSans(
                  color: AppColors.white30,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                _PhoneInputFormatter(),
              ],
            ),
          ),
          if (_isPhoneValid)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle, color: AppColors.successGreen, size: 24)
                  .animate()
                  .scale(begin: const Offset(0, 0)),
            ),
        ],
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

  Widget _buildContinueButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading || !_isPhoneValid ? null : _handleContinue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: _isPhoneValid
              ? const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                )
              : null,
          color: _isPhoneValid ? null : AppColors.white10,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPhoneValid
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
                  'Continue',
                  style: GoogleFonts.dmSans(
                    color: _isPhoneValid ? Colors.black : AppColors.white50,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  Widget _buildTermsText() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'By continuing, you agree to our ',
          style: GoogleFonts.dmSans(
            color: AppColors.white50,
            fontSize: 12,
          ),
          children: [
            TextSpan(
              text: 'Terms of Service',
              style: GoogleFonts.dmSans(
                color: AppColors.hyperLime,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: GoogleFonts.dmSans(
                color: AppColors.hyperLime,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms);
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
