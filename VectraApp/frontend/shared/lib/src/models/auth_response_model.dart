import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Auth response model for login endpoint
class AuthResponseModel extends Equatable {
  final String status;
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String refreshTokenId;

  const AuthResponseModel({
    required this.status,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.refreshTokenId,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      status: json['status'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      refreshTokenId: json['refreshTokenId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'refreshTokenId': refreshTokenId,
    };
  }

  @override
  List<Object?> get props => [
    status,
    user,
    accessToken,
    refreshToken,
    refreshTokenId,
  ];
}

/// Registration response model
class RegisterResponseModel extends Equatable {
  final String status;
  final UserModel user;

  const RegisterResponseModel({required this.status, required this.user});

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      status: json['status'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [status, user];
}

/// Token refresh response model
class TokenRefreshResponseModel extends Equatable {
  final String status;
  final String accessToken;
  final String refreshToken;
  final String refreshTokenId;

  const TokenRefreshResponseModel({
    required this.status,
    required this.accessToken,
    required this.refreshToken,
    required this.refreshTokenId,
  });

  factory TokenRefreshResponseModel.fromJson(Map<String, dynamic> json) {
    return TokenRefreshResponseModel(
      status: json['status'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      refreshTokenId: json['refreshTokenId'] as String,
    );
  }

  @override
  List<Object?> get props => [
    status,
    accessToken,
    refreshToken,
    refreshTokenId,
  ];
}
