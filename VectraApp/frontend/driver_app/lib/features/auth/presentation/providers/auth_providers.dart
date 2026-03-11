import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_tokens.dart';

/// Auth state class
class AuthStateData {
  final AuthState state;
  final AuthTokens? tokens;
  final AuthError? error;
  final String? identifier;
  final String channel;
  final bool requiresOnboarding;
  final String? debugOtp;

  AuthStateData({
    this.state = AuthState.initial,
    this.tokens,
    this.error,
    this.identifier,
    this.channel = 'phone',
    this.requiresOnboarding = false,
    this.debugOtp,
  });

  AuthStateData copyWith({
    AuthState? state,
    AuthTokens? tokens,
    AuthError? error,
    String? identifier,
    String? channel,
    bool? requiresOnboarding,
    String? debugOtp,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      tokens: tokens ?? this.tokens,
      error: error,
      identifier: identifier ?? this.identifier,
      channel: channel ?? this.channel,
      requiresOnboarding: requiresOnboarding ?? this.requiresOnboarding,
      debugOtp: debugOtp ?? this.debugOtp,
    );
  }

  bool get isAuthenticated => state == AuthState.authenticated;
  bool get isLoading => state == AuthState.loading || state == AuthState.otpVerifying;
}

/// Auth state notifier for managing authentication
class AuthNotifier extends StateNotifier<AuthStateData> {
  final AuthRepository _repository;

  AuthNotifier({
    required AuthRepository repository,
  })  : _repository = repository,
        super(AuthStateData()) {
    _checkAuthStatus();
  }

  /// Check initial authentication status
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(state: AuthState.loading);

    try {
      final isAuthenticated = await _repository.isAuthenticated();
      if (isAuthenticated) {
        final role = await _repository.getUserRole();
        state = state.copyWith(
          state: AuthState.authenticated,
          tokens: AuthTokens(
            accessToken: '',
            refreshToken: '',
            role: role ?? 'DRIVER',
          ),
          requiresOnboarding: false,
        );
      } else {
        state = state.copyWith(state: AuthState.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(state: AuthState.unauthenticated);
    }
  }

  /// Send OTP to phone number
  Future<bool> sendOtp(String identifier, {String channel = 'phone'}) async {
    state = state.copyWith(
      state: AuthState.loading,
      identifier: identifier,
      channel: channel,
      debugOtp: null,
    );

    try {
      final request = OtpRequest(identifier: identifier, channel: channel);
      final result = await _repository.sendOtp(request);

      if (result.success) {
        state = state.copyWith(
          state: AuthState.otpSent,
          debugOtp: result.devOtp,
        );
        return true;
      } else {
        state = state.copyWith(
          state: AuthState.error,
          error: AuthError(message: 'Failed to send OTP'),
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        error: e is AuthError ? e : AuthError(message: e.toString()),
      );
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(String otp) async {
    if (state.identifier == null) {
      state = state.copyWith(
        state: AuthState.error,
        error: AuthError(message: 'Phone number not set'),
      );
      return false;
    }

    state = state.copyWith(state: AuthState.otpVerifying);

    try {
      final verification = OtpVerification(
        identifier: state.identifier!,
        otp: otp,
      );
      final tokens = await _repository.verifyOtp(verification);

      // Validate driver role
      if (tokens.role != 'DRIVER') {
        state = state.copyWith(
          state: AuthState.error,
          error: AuthError(
            message: 'This app is only for drivers',
            code: 'INVALID_ROLE',
          ),
        );
        await _repository.logout();
        return false;
      }

      state = state.copyWith(
        state: AuthState.authenticated,
        tokens: tokens,
        requiresOnboarding: tokens.isNewUser,
        debugOtp: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        error: e is AuthError ? e : AuthError(message: e.toString()),
      );
      return false;
    }
  }

  /// Resend OTP
  Future<bool> resendOtp() async {
    if (state.identifier == null) return false;
    return await sendOtp(state.identifier!, channel: state.channel);
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(state: AuthState.loading);

    try {
      await _repository.logout();
      state = AuthStateData(state: AuthState.unauthenticated);
    } catch (e) {
      state = AuthStateData(state: AuthState.unauthenticated);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset to initial state
  void reset() {
    state = AuthStateData(state: AuthState.unauthenticated);
  }

  void completeOnboarding() {
    state = state.copyWith(requiresOnboarding: false);
  }
}

// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository: repository);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authProvider).state;
});

final authErrorProvider = Provider<AuthError?>((ref) {
  return ref.watch(authProvider).error;
});
