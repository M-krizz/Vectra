part of 'auth_bloc.dart';

/// Auth states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {}

/// Loading state (API in progress)
class AuthLoading extends AuthState {}

/// OTP was sent successfully — waiting for user to enter code
class AuthOtpSent extends AuthState {
  final String identifier;
  final String? devOtp; // only present in development mode

  const AuthOtpSent({required this.identifier, this.devOtp});

  @override
  List<Object?> get props => [identifier, devOtp];
}

/// OTP verified — user registered for first time, needs to complete profile
class AuthOtpVerificationRequired extends AuthState {
  final UserModel user;

  const AuthOtpVerificationRequired({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is fully authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {}

/// Auth error with a message
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
