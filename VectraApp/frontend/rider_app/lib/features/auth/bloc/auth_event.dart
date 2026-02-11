part of 'auth_bloc.dart';

/// Auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is already authenticated
class AuthCheckRequested extends AuthEvent {}

/// Login with email and password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Register new rider
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String phone;
  final String fullName;
  final String password;

  const AuthRegisterRequested({
    required this.email,
    required this.phone,
    required this.fullName,
    required this.password,
  });

  @override
  List<Object?> get props => [email, phone, fullName, password];
}

/// Logout user
class AuthLogoutRequested extends AuthEvent {}
