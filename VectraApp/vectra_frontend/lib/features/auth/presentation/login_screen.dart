import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background visualization (Placeholder for ActiveEcoBackground)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF0F1A0F), Colors.black],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'VECTRA',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppColors.hyperLime,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5),
                  
                  const SizedBox(height: 60),
                  
                  if (!_otpSent) ...[
                     TextField(
                       controller: _phoneController,
                       keyboardType: TextInputType.phone,
                       style: const TextStyle(color: Colors.white),
                       decoration: const InputDecoration(
                         hintText: '(555) 123-4567',
                         labelText: 'Phone Number',
                         prefixIcon: Icon(Icons.phone, color: AppColors.white70),
                       ),
                     ),
                     const SizedBox(height: 24),
                     ElevatedButton(
                       onPressed: _isLoading ? null : _handleRequestOtp,
                       child: _isLoading 
                         ? const CircularProgressIndicator(color: Colors.black)
                         : const Text('Continue'),
                     ),
                  ] else ...[
                     TextField(
                       controller: _otpController,
                       keyboardType: TextInputType.number,
                       style: const TextStyle(color: Colors.white),
                       decoration: const InputDecoration(
                         hintText: '1234',
                         labelText: 'Enter Verification Code',
                         prefixIcon: Icon(Icons.lock_outline, color: AppColors.white70),
                       ),
                     ),
                     const SizedBox(height: 24),
                     ElevatedButton(
                       onPressed: _isLoading ? null : _handleVerifyOtp,
                       child: _isLoading 
                         ? const CircularProgressIndicator(color: Colors.black)
                         : const Text('Verify & Login'),
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

  Future<void> _handleRequestOtp() async {
    setState(() => _isLoading = true);
    try {
      final devOtp = await ref.read(authRepositoryProvider).requestOtp(_phoneController.text);
      if (mounted) {
        setState(() => _otpSent = true);
        // Show OTP in snackbar for dev testing (remove in production)
        if (devOtp != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('DEV MODE - Your OTP: $devOtp'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 10),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final token = await ref.read(authRepositoryProvider).verifyOtp(_phoneController.text, _otpController.text);
      if (mounted) {
         context.go('/dashboard');
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Success! Token: $token')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
