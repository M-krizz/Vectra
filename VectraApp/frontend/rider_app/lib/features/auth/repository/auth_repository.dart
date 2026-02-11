import 'dart:convert';

import 'package:shared/shared.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository({
    required ApiClient apiClient,
    required StorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  /// Get current user from storage
  Future<UserModel?> getCurrentUser() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      try {
        final json = jsonDecode(userData) as Map<String, dynamic>;
        return UserModel.fromJson(json);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Login with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'deviceInfo': 'Vectra Rider App - Android',
      },
    );

    final authResponse = AuthResponseModel.fromJson(response.data);

    // Save tokens
    await _storageService.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      refreshTokenId: authResponse.refreshTokenId,
    );

    // Save user data
    await _storageService.saveUserData(jsonEncode(authResponse.user.toJson()));

    return authResponse.user;
  }

  /// Register new rider
  Future<UserModel> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.registerRider,
      data: {
        'email': email,
        'phone': phone,
        'fullName': fullName,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final refreshTokenId = await _storageService.getRefreshTokenId();
      if (refreshTokenId != null) {
        await _apiClient.post(
          ApiConstants.logout,
          data: {'refreshTokenId': refreshTokenId},
        );
      }
    } finally {
      await _storageService.clearAll();
    }
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    final refreshToken = await _storageService.getRefreshToken();
    final refreshTokenId = await _storageService.getRefreshTokenId();

    if (refreshToken == null || refreshTokenId == null) {
      throw UnauthorizedException(message: 'No refresh token available');
    }

    final response = await _apiClient.post(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshToken, 'refreshTokenId': refreshTokenId},
    );

    final data = response.data as Map<String, dynamic>;

    await _storageService.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
      refreshTokenId: data['refreshTokenId'],
    );
  }

  /// Get user profile
  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiConstants.profileMe);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
