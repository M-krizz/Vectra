import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/app_theme.dart';
import '../../../common/widgets/loading_button.dart';
import '../bloc/auth_bloc.dart';

/// First screen — user enters phone or email to receive OTP
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isEmail(String value) => value.contains('@');

  void _onSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    String identifier = _controller.text.trim();
    final channel = _isEmail(identifier) ? 'email' : 'phone';

    // Format phone number to E.164 for Twilio
    if (channel == 'phone') {
      identifier = identifier.replaceAll(RegExp(r'[\s\-]'), '');
      if (!identifier.startsWith('+')) {
        identifier = '+91$identifier'; // Default to India country code
      }
    }

    context.read<AuthBloc>().add(
      AuthOtpRequested(identifier: identifier, channel: channel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          // Navigation to OTP screen is handled by app_router.dart
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // Brand Logo / Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.electric_bolt_rounded,
                      color: Theme.of(context).colorScheme.surface,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Welcome to Vectra',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your phone number or email to get started. We\'ll send you a one-time verification code.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Phone / Email input
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.telephoneNumber,
                      AutofillHints.email,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Phone or Email',
                      hintText: '+91 XXXXX XXXXX or you@email.com',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number or email';
                      }
                      final v = value.trim();
                      if (!_isEmail(v) && v.length < 7) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return LoadingButton(
                        onPressed: _onSendOtp,
                        isLoading: state is AuthLoading,
                        text: 'Send OTP',
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'By continuing you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
