import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../presentation/providers/auth_providers.dart';

/// Role guard widget that only allows drivers to access content
class DriverRoleGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;
  final VoidCallback? onAccessDenied;

  const DriverRoleGuard({
    super.key,
    required this.child,
    this.fallback,
    this.onAccessDenied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return fallback ?? const _AccessDeniedScreen(message: 'Please log in to continue');
    }

    final role = authState.tokens?.role;
    if (role != UserRoles.driver) {
      onAccessDenied?.call();
      return fallback ?? const _AccessDeniedScreen(message: 'This app is only for drivers');
    }

    return child;
  }
}

/// Auth guard that requires authentication
class AuthGuard extends ConsumerWidget {
  final Widget child;
  final Widget loginScreen;

  const AuthGuard({
    super.key,
    required this.child,
    required this.loginScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      return child;
    }

    return loginScreen;
  }
}

/// Loading guard that shows loading during auth check
class AuthLoadingGuard extends ConsumerWidget {
  final Widget child;
  final Widget loginScreen;
  final Widget? loadingWidget;

  const AuthLoadingGuard({
    super.key,
    required this.child,
    required this.loginScreen,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    switch (authState.state) {
      case AuthState.initial:
      case AuthState.loading:
        return loadingWidget ?? const _LoadingScreen();
      case AuthState.authenticated:
        return child;
      default:
        return loginScreen;
    }
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  final String message;

  const _AccessDeniedScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                color: Color(0xFFFF3B30),
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080808),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFCCFF00),
        ),
      ),
    );
  }
}
