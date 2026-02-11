import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared/shared.dart';

import '../repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Authentication BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    
    // Add logging to state changes
    stream.listen((state) {
      print('[AuthBloc] 📍 State changed: ${state.runtimeType} - $state');
    });
  }

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
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('[AuthBloc] 🔐 Login requested for: ${event.email}');
    emit(AuthLoading());

    try {
      print('[AuthBloc] 🔄 Calling authRepository.login()');
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      print('[AuthBloc] ✅ Login successful! User: ${user.id} (${user.fullName})');
      print('[AuthBloc] 📤 Emitting AuthAuthenticated');
      emit(AuthAuthenticated(user: user));
    } on ApiException catch (e) {
      print('[AuthBloc] ❌ API Error during login: ${e.message}');
      emit(AuthError(message: e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      print('[AuthBloc] ❌ Unexpected error during login: $e');
      emit(AuthError(message: 'An unexpected error occurred'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authRepository.register(
        email: event.email,
        phone: event.phone,
        fullName: event.fullName,
        password: event.password,
      );
      emit(const AuthRegistrationSuccess());
      emit(AuthUnauthenticated());
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authRepository.logout();
    } catch (_) {
      // Ignore logout errors, clear local data anyway
    }

    emit(AuthUnauthenticated());
  }
}
