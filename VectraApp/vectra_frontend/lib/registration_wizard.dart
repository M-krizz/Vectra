import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'floating_nav_bar.dart';
import 'theme/app_colors.dart';
import 'widgets/premium_text_field.dart';
import 'widgets/otp_input.dart';
import 'widgets/document_upload_zone.dart';
import 'providers/registration_providers.dart';
import 'verification_hud.dart';
import 'widgets/active_eco_background.dart';

class RegistrationWizard extends ConsumerStatefulWidget {
  final String userRole;
  
  const RegistrationWizard({super.key, required this.userRole});

  @override
  ConsumerState<RegistrationWizard> createState() => _RegistrationWizardState();
}

class _RegistrationWizardState extends ConsumerState<RegistrationWizard> {
  @override
  Widget build(BuildContext context) {
    final step = ref.watch(stepProvider);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Stack(
        children: [
          // Background (Continuous)
          const ActiveEcoBackground(),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _buildGlassCard(
                          context,
                          ref,
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildStepContent(context, ref, step),
                          ),
                        ),
                        // Always keep bottom spacer to ensure content can be scrolled fully
                        const SizedBox(height: 150),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Navigation Bar (Hidden when keyboard is active)
          if (!isKeyboardVisible)
            FloatingNavBar(
              currentStep: step,
              totalSteps: widget.userRole == 'rider' ? 3 : 4,
              enabled: _isStepValid(ref, step),
              onNext: () {
                if (_isStepValid(ref, step)) {
                  final isLastStep =
                      widget.userRole == 'rider' ? step == 2 : step == 3;

                  if (!isLastStep) {
                    ref.read(stepProvider.notifier).state++;
                  } else {
                    // Navigate to verification HUD
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VerificationHUD(),
                      ),
                    );
                  }
                }
              },
              onBack: step == 0
                  ? null
                  : () => ref.read(stepProvider.notifier).state--,
            ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, WidgetRef ref, Widget child) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      // Shadow remains on the outer container so it sits behind the blur
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 50,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.carbonGrey.withOpacity(0.75),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.white10),
            ),
            child: child,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
          begin: const Offset(0.95, 0.95),
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildStepContent(BuildContext context, WidgetRef ref, int step) {
    return Column(
      key: ValueKey(step),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        Text(
          'Step ${step + 1} of ${widget.userRole == 'rider' ? 3 : 4}',
          style: TextStyle(
            color: AppColors.white70,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),

        // Step title
        Text(
          _getStepTitle(step),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Step description
        Text(
          _getStepDescription(step),
          style: TextStyle(
            color: AppColors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),

        // Step content
        switch (step) {
          0 => _buildNameEmailStep(ref),
          1 => _buildPhoneStep(ref),
          2 => _buildOtpStep(ref),
          3 => _buildDocumentStep(ref),
          _ => const SizedBox(),
        },
      ],
    );
  }

  String _getStepTitle(int step) {
    return switch (step) {
      0 => 'Your Details',
      1 => 'Phone Number',
      2 => 'Verify Code',
      3 => 'Upload Documents',
      _ => '',
    };
  }

  String _getStepDescription(int step) {
    return switch (step) {
      0 => 'Tell us your name and email address',
      1 => 'Enter your phone number for verification',
      2 => 'Enter the 4-digit code we sent you',
      3 => widget.userRole == 'driver' 
          ? 'Upload your driver license for verification'
          : 'Upload your ID for verification',
      _ => '',
    };
  }

  Widget _buildNameEmailStep(WidgetRef ref) {
    final nameInput = ref.watch(nameInputProvider);
    final emailInput = ref.watch(emailInputProvider);
    final emailValidation = ref.watch(emailValidationProvider);

    return Column(
      children: [
        PremiumTextField(
          hint: 'Full Name',
          onChanged: (value) {
            ref.read(nameInputProvider.notifier).state = value;
          },
          isValid: nameInput.trim().length >= 2,
          showError: nameInput.isNotEmpty && nameInput.trim().length < 2,
          keyboardType: TextInputType.name,
          prefixIcon: Icon(
            nameInput.trim().length >= 2
                ? Icons.person
                : Icons.person_outline,
            color: nameInput.trim().length >= 2
                ? AppColors.successGreen
                : AppColors.white70,
          ),
        ),
        const SizedBox(height: 20),
        PremiumTextField(
          hint: 'Email Address',
          onChanged: (value) {
            ref.read(emailInputProvider.notifier).state = value;
          },
          isValid: emailValidation == ValidationState.valid,
          showError: emailValidation == ValidationState.invalid && emailInput.isNotEmpty,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(
            emailValidation == ValidationState.valid
                ? Icons.email
                : Icons.email_outlined,
            color: emailValidation == ValidationState.valid
                ? AppColors.successGreen
                : AppColors.white70,
          ),
        ),
        if (emailValidation == ValidationState.invalid && emailInput.isNotEmpty) ...[ 
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.errorRed, size: 16),
              const SizedBox(width: 8),
              Text(
                'Please enter a valid email address',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 14,
                ),
              ),
            ],
          ).animate().shake(duration: 400.ms),
        ],
      ],
    );
  }

  Widget _buildPhoneStep(WidgetRef ref) {
    final validation = ref.watch(phoneValidationProvider);
    final input = ref.watch(phoneInputProvider);

    return Column(
      children: [
        PremiumTextField(
          hint: 'Phone number',
          onChanged: (value) {
            ref.read(phoneInputProvider.notifier).state = value;
          },
          isValid: validation == ValidationState.valid,
          showError: validation == ValidationState.invalid && input.isNotEmpty,
          keyboardType: TextInputType.phone,
          prefixIcon: Icon(
            validation == ValidationState.valid
                ? Icons.phone
                : Icons.phone_outlined,
            color: validation == ValidationState.valid
                ? AppColors.successGreen
                : AppColors.white70,
          ),
        ),
        if (validation == ValidationState.invalid && input.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.errorRed, size: 16),
              const SizedBox(width: 8),
              Text(
                'Please enter a valid phone number',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 14,
                ),
              ),
            ],
          ).animate().shake(duration: 400.ms),
        ],
      ],
    );
  }

  Widget _buildOtpStep(WidgetRef ref) {
    return OtpInput(
      onCompleted: (otp) {
        ref.read(otpProvider.notifier).state = otp;
      },
    );
  }

  Widget _buildDocumentStep(WidgetRef ref) {
    final isUploading = ref.watch(documentUploadedProvider);
    final progress = ref.watch(uploadProgressProvider);

    return DocumentUploadZone(
      onUpload: () async {
        // Simulate upload
        ref.read(documentUploadedProvider.notifier).state = true;
        for (int i = 0; i <= 100; i += 10) {
          await Future.delayed(const Duration(milliseconds: 200));
          ref.read(uploadProgressProvider.notifier).state = i / 100;
        }
      },
      isUploading: isUploading,
      progress: progress,
    );
  }

  bool _isStepValid(WidgetRef ref, int step) {
    return switch (step) {
      0 => ref.watch(nameInputProvider).trim().length >= 2 &&
           ref.watch(emailValidationProvider) == ValidationState.valid,
      1 => ref.watch(phoneValidationProvider) == ValidationState.valid,
      2 => ref.watch(otpValidationProvider),
      3 => ref.watch(uploadProgressProvider) >= 1.0,
      _ => false,
    };
  }
}

