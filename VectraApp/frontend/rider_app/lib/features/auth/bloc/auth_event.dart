part of 'auth_bloc.dart';

/// Auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is already authenticated
class AuthCheckRequested extends AuthEvent {}

/// Step 1 – Request OTP for phone or email
class AuthOtpRequested extends AuthEvent {
  final String identifier; // phone number or email
  final String channel;   // 'phone' or 'email'

  const AuthOtpRequested({
    required this.identifier,
    this.channel = 'phone',
  });

  @override
  List<Object?> get props => [identifier, channel];
}

/// Step 2 – Submit OTP code for verification
class AuthVerifyOtpRequested extends AuthEvent {
  final String identifier;
  final String code;

  const AuthVerifyOtpRequested({
    required this.identifier,
    required this.code,
  });

  @override
  List<Object?> get props => [identifier, code];
}

/// Complete profile with full name (first-time users)
class AuthCompleteProfileRequested extends AuthEvent {
  final String fullName;
  const AuthCompleteProfileRequested({required this.fullName});

  @override
  List<Object?> get props => [fullName];
}

/// Update specific profile details (name, email, gender)
class AuthUpdateProfileRequested extends AuthEvent {
  final String? fullName;
  final String? email;
  final String? gender;

  const AuthUpdateProfileRequested({
    this.fullName,
    this.email,
    this.gender,
  });

  @override
  List<Object?> get props => [fullName, email, gender];
}

/// Logout user
class AuthLogoutRequested extends AuthEvent {}
