import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_tokens.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/api/api_client.dart';

/// Auth state class
class AuthStateData {
  final AuthState state;
  final AuthTokens? tokens;
  final AuthError? error;
  final String? phoneNumber;

  AuthStateData({
    this.state = AuthState.initial,
    this.tokens,
    this.error,
    this.phoneNumber,
  });

  AuthStateData copyWith({
    AuthState? state,
    AuthTokens? tokens,
    AuthError? error,
    String? phoneNumber,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      tokens: tokens ?? this.tokens,
      error: error,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  bool get isAuthenticated => state == AuthState.authenticated;
  bool get isLoading => state == AuthState.loading || state == AuthState.otpVerifying;
}

/// Auth state notifier for managing authentication
class AuthNotifier extends StateNotifier<AuthStateData> {
  final AuthRepository _repository;
  final SecureStorageService _storage;

  AuthNotifier({
    required AuthRepository repository,
    required SecureStorageService storage,
  })  : _repository = repository,
        _storage = storage,
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
        );
      } else {
        state = state.copyWith(state: AuthState.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(state: AuthState.unauthenticated);
    }
  }

  /// Send OTP to phone number
  Future<bool> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      state: AuthState.loading,
      phoneNumber: phoneNumber,
    );

    try {
      print('AuthNotifier: Sending OTP to $phoneNumber');
      final request = OtpRequest(phoneNumber: phoneNumber);
      final success = await _repository.sendOtp(request);
      print('AuthNotifier: Repository matched success: $success');

      if (success) {
        state = state.copyWith(state: AuthState.otpSent);
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
    if (state.phoneNumber == null) {
      state = state.copyWith(
        state: AuthState.error,
        error: AuthError(message: 'Phone number not set'),
      );
      return false;
    }

    state = state.copyWith(state: AuthState.otpVerifying);

    try {
      final verification = OtpVerification(
        phoneNumber: state.phoneNumber!,
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
    if (state.phoneNumber == null) return false;
    return await sendOtp(state.phoneNumber!);
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
}

// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthNotifier(repository: repository, storage: storage);
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
