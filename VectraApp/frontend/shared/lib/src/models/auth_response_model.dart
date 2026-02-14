import 'user_model.dart';

/// Response model for authentication endpoints (login)
class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final String refreshTokenId;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.refreshTokenId,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      refreshTokenId: json['refreshTokenId'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
