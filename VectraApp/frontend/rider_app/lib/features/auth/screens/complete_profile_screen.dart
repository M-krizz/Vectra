import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/app_theme.dart';
import '../../../common/widgets/loading_button.dart';
import '../bloc/auth_bloc.dart';

/// Screen shown after first-time OTP verification to collect the user's name.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthCompleteProfileRequested(fullName: _controller.text.trim()),
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
          // Navigation to /home is handled by app_router.dart on AuthAuthenticated
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

                  // Icon
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
                      Icons.person_rounded,
                      color: Theme.of(context).colorScheme.surface,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Welcome to Vectra!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What should we call you?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Mohan Krishnan',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return LoadingButton(
                        onPressed: _onSubmit,
                        isLoading: state is AuthLoading,
                        text: 'Continue',
                      );
                    },
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
