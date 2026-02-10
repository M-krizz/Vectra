import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import '../providers/auth_providers.dart';
import 'otp_verification_screen.dart';

/// Phone input screen for driver authentication — Premium UI
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
    _phoneFocusNode.addListener(() => setState(() {}));
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

    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final fullPhone = '$_selectedCountryCode$phone';

    final success = await ref.read(authProvider.notifier).sendOtp(phone);

    if (success && mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OtpVerificationScreen(phoneNumber: fullPhone),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      body: Stack(
        children: [
          // Background with subtle amber accent orbs
          _buildBackground(size),

          // Main content
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
                      SizedBox(height: size.height * 0.06),
                      _buildBrandMark(),
                      const SizedBox(height: 40),
                      _buildTitle(),
                      const SizedBox(height: 40),
                      _buildPhoneInput(),
                      const SizedBox(height: 16),
                      if (authState.error != null)
                        _buildErrorMessage(authState.error!.message),
                      const SizedBox(height: 32),
                      _buildContinueButton(authState.isLoading),
                      const SizedBox(height: 40),
                      _buildTermsText(),
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
        // Base dark
        Container(color: AppColors.voidBlack),

        // Top-right amber orb
        Positioned(
          top: -size.height * 0.12,
          right: -size.width * 0.25,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.hyperLime.withOpacity(0.10),
                  AppColors.hyperLime.withOpacity(0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Bottom-left subtle orb
        Positioned(
          bottom: -size.height * 0.15,
          left: -size.width * 0.3,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.neonGreen.withOpacity(0.06),
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
        // Back button — glass style
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
        // Driver badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.hyperLime.withOpacity(0.15),
                AppColors.neonGreen.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: AppColors.hyperLime.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.hyperLime,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DRIVER',
                style: GoogleFonts.outfit(
                  color: AppColors.hyperLime,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandMark() {
    return Center(
      child: Column(
        children: [
          // Glowing icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.hyperLime.withOpacity(0.2),
                  AppColors.neonGreen.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.hyperLime.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.hyperLime.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.hyperLime,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'VECTRA',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
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
          'Welcome,',
          style: GoogleFonts.outfit(
            color: AppColors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your phone\nnumber to get started',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.25,
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

  Widget _buildPhoneInput() {
    final isFocused = _phoneFocusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused
              ? AppColors.hyperLime.withOpacity(0.6)
              : AppColors.white10,
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.hyperLime.withOpacity(0.1),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Country code selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              underline: const SizedBox(),
              dropdownColor: AppColors.carbonGrey,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: AppColors.white50, size: 20),
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                DropdownMenuItem(value: '+61', child: Text('🇦🇺 +61')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCountryCode = value ?? '+91';
                });
              },
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.white10),
          // Phone number input
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
                  color: AppColors.white20,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                _PhoneInputFormatter(),
              ],
            ),
          ),
          // Validity check icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _isPhoneValid
                ? Padding(
                    key: const ValueKey('check'),
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.successGreen.withOpacity(0.2),
                      ),
                      child: const Icon(Icons.check,
                          color: AppColors.successGreen, size: 18),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
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
            child:
                const Icon(Icons.error_outline, color: AppColors.errorRed, size: 16),
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

  Widget _buildContinueButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading || !_isPhoneValid ? null : _handleContinue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isPhoneValid
              ? const LinearGradient(
                  colors: [AppColors.hyperLime, AppColors.neonGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isPhoneValid ? null : AppColors.carbonGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: _isPhoneValid
              ? null
              : Border.all(color: AppColors.white10),
          boxShadow: _isPhoneValid
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
                    Text(
                      'Continue',
                      style: GoogleFonts.outfit(
                        color:
                            _isPhoneValid ? Colors.black : AppColors.white30,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isPhoneValid) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.black.withOpacity(0.7), size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text.rich(
          TextSpan(
            text: 'By continuing, you agree to our ',
            style: GoogleFonts.dmSans(
              color: AppColors.white30,
              fontSize: 12,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: 'Terms of Service',
                style: GoogleFonts.dmSans(
                  color: AppColors.hyperLime.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: GoogleFonts.dmSans(
                  color: AppColors.hyperLime.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
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
