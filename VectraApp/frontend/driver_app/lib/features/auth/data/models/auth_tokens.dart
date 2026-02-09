/// Authentication tokens model
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String role;
  final String? userId;
  final DateTime? expiresAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    this.userId,
    this.expiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      role: json['role'] as String? ?? 'DRIVER',
      userId: json['user_id'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'role': role,
      'user_id': userId,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  String toString() {
    return 'AuthTokens(role: $role, userId: $userId, expiresAt: $expiresAt)';
  }
}

/// OTP request model
class OtpRequest {
  final String phoneNumber;
  final String countryCode;

  OtpRequest({
    required this.phoneNumber,
    this.countryCode = '+91',
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'country_code': countryCode,
    };
  }

  String get fullPhoneNumber => '$countryCode$phoneNumber';
}

/// OTP verification model
class OtpVerification {
  final String phoneNumber;
  final String otp;
  final String? deviceToken;

  OtpVerification({
    required this.phoneNumber,
    required this.otp,
    this.deviceToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'otp': otp,
      if (deviceToken != null) 'device_token': deviceToken,
    };
  }
}

/// Auth state for the app
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  otpVerifying,
  error,
}

/// Auth error model
class AuthError {
  final String message;
  final String? code;

  AuthError({
    required this.message,
    this.code,
  });

  factory AuthError.fromJson(Map<String, dynamic> json) {
    return AuthError(
      message: json['message'] as String? ?? 'Unknown error',
      code: json['code'] as String?,
    );
  }

  @override
  String toString() => message;
}
