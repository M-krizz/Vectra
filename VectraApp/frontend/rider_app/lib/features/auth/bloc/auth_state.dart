part of 'auth_bloc.dart';

/// Auth states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {}

/// Loading state
class AuthLoading extends AuthState {}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {}

/// Auth error
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Registration successful - user needs to login
class AuthRegistrationSuccess extends AuthState {
  final String message;

  const AuthRegistrationSuccess({
    this.message = 'Registration successful! Please login.',
  });

  @override
  List<Object?> get props => [message];
}
