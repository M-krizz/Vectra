import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Authentication BLoC — OTP-only login
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthOtpRequested>(_onAuthOtpRequested);
    on<AuthVerifyOtpRequested>(_onAuthVerifyOtpRequested);
    on<AuthCompleteProfileRequested>(_onAuthCompleteProfileRequested);
    on<AuthUpdateProfileRequested>(_onAuthUpdateProfileRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);

    stream.listen((state) {
      debugPrint('[AuthBloc] 📍 State: ${state.runtimeType}');
    });
  }

  // ── Check existing session ──────────────────────────────────

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
          return;
        }
      }
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // ── Step 1: Request OTP ─────────────────────────────────────

  Future<void> _onAuthOtpRequested(
    AuthOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      debugPrint('[AuthBloc] 📤 Requesting OTP for: ${event.identifier}');
      final result = await _authRepository.requestOtp(
        identifier: event.identifier,
        channel: event.channel,
      );
      final devOtp = result['devOtp'] as String?;
      debugPrint('[AuthBloc] ✅ OTP sent. DevOTP: $devOtp');
      emit(AuthOtpSent(identifier: event.identifier, devOtp: devOtp));
    } on ApiException catch (e) {
      debugPrint('[AuthBloc] ❌ OTP request failed: ${e.message}');
      emit(AuthError(message: e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      debugPrint('[AuthBloc] ❌ Unexpected error: $e');
      emit(AuthError(message: 'Failed to send OTP. Please try again.'));
      emit(AuthUnauthenticated());
    }
  }

  // ── Step 2: Verify OTP ──────────────────────────────────────

  Future<void> _onAuthVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      debugPrint('[AuthBloc] 🔑 Verifying OTP for: ${event.identifier}');
      final user = await _authRepository.verifyOtpAndLogin(
        identifier: event.identifier,
        code: event.code,
        roleHint: 'RIDER',
      );
      debugPrint('[AuthBloc] ✅ Verified. User: ${user.id} (${user.fullName})');

      if (user.fullName == null || user.fullName!.isEmpty) {
        // First-time user — flag for onboarding and ask for name
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('just_registered', true);
        emit(AuthOtpVerificationRequired(user: user));
      } else {
        emit(AuthAuthenticated(user: user));
      }
    } on ApiException catch (e) {
      debugPrint('[AuthBloc] ❌ OTP verification failed: ${e.message}');
      emit(AuthError(message: e.message));
      // Go back to OTP input, not all the way to the start
      emit(AuthOtpSent(identifier: event.identifier));
    } catch (e) {
      debugPrint('[AuthBloc] ❌ Unexpected error: $e');
      emit(AuthError(message: 'Verification failed. Please try again.'));
      emit(AuthOtpSent(identifier: event.identifier));
    }
  }

  // ── Complete profile (first-time users) ────────────────────

  Future<void> _onAuthCompleteProfileRequested(
    AuthCompleteProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.completeProfile(fullName: event.fullName);
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to save profile. Please try again.'));
      final user = await _authRepository.getCurrentUser();
      if (user != null) emit(AuthOtpVerificationRequired(user: user));
    }
  }

  // ── Update profile ──────────────────────────────────────────

  Future<void> _onAuthUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      await _authRepository.updateProfile(
        fullName: event.fullName,
        email: event.email,
        gender: event.gender,
      );
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      // In a real app we might emit a side-effect error here, or use a separate ProfileBloc.
      debugPrint('[AuthBloc] ❌ Profile update failed: $e');
    }
  }

  // ── Logout ──────────────────────────────────────────────────

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
    } catch (_) {}
    emit(AuthUnauthenticated());
  }
}
