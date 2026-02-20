import 'dart:convert';

import 'package:shared/shared.dart';

/// Set to true to bypass the real backend and use mock data.
/// Flip to false when the backend API is reachable.
const bool kUseMockAuth = true;

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository({
    required ApiClient apiClient,
    required StorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  // ─── Mock helpers ────────────────────────────────────────────────────────

  static UserModel _mockUser(String email) => UserModel(
    id: 'mock_user_001',
    email: email,
    fullName: email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ').trim(),
    phone: '+91 9876543210',
    role: 'rider',
  );

  static const String _mockAccessToken = 'mock_access_token';
  static const String _mockRefreshToken = 'mock_refresh_token';
  static const String _mockRefreshTokenId = 'mock_refresh_token_id';

  // ─── Public API ──────────────────────────────────────────────────────────

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
    if (kUseMockAuth) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock validation — any non-empty credentials work
      if (email.isEmpty || password.isEmpty) {
        throw ApiException(
          message: 'Email and password are required',
          statusCode: 400,
        );
      }

      final user = _mockUser(email);

      await _storageService.saveTokens(
        accessToken: _mockAccessToken,
        refreshToken: _mockRefreshToken,
        refreshTokenId: _mockRefreshTokenId,
      );
      await _storageService.saveUserData(jsonEncode(user.toJson()));

      return user;
    }

    // ── Real backend path ──────────────────────────────────────────────────────
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'deviceInfo': 'Vectra Rider App - Android',
      },
    );

    final authResponse = AuthResponseModel.fromJson(response.data as Map<String, dynamic>);

    await _storageService.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      refreshTokenId: authResponse.refreshTokenId,
    );
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
    if (kUseMockAuth) {
      await Future.delayed(const Duration(milliseconds: 800));

      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw ApiException(
          message: 'All fields are required',
          statusCode: 400,
        );
      }

      final user = UserModel(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        phone: phone,
        role: 'rider',
      );

      await _storageService.saveTokens(
        accessToken: _mockAccessToken,
        refreshToken: _mockRefreshToken,
        refreshTokenId: _mockRefreshTokenId,
      );
      await _storageService.saveUserData(jsonEncode(user.toJson()));

      return user;
    }

    // ── Real backend path ──────────────────────────────────────────────────────
    final response = await _apiClient.post(
      ApiConstants.registerRider,
      data: {
        'email': email,
        'phone': phone,
        'fullName': fullName,
        'password': password,
      },
    );

    final authResponse = AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    await _storageService.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      refreshTokenId: authResponse.refreshTokenId,
    );
    await _storageService.saveUserData(jsonEncode(authResponse.user.toJson()));
    return authResponse.user;
  }

  /// Logout user
  Future<void> logout() async {
    try {
      if (!kUseMockAuth) {
        final refreshTokenId = await _storageService.getRefreshTokenId();
        if (refreshTokenId != null) {
          await _apiClient.post(
            ApiConstants.logout,
            data: {'refreshTokenId': refreshTokenId},
          );
        }
      }
    } finally {
      await _storageService.clearAll();
    }
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    if (kUseMockAuth) return; // No-op in mock mode

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
    if (kUseMockAuth) {
      final user = await getCurrentUser();
      if (user != null) return user;
      throw ApiException(message: 'Not logged in', statusCode: 401);
    }

    final response = await _apiClient.get(ApiConstants.profileMe);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
