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
    // MOCK IMPLEMENTATION
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final mockUser = UserModel(
      id: 'mock_user_123',
      email: email,
      phone: '9876543210',
      fullName: 'Mock User',
      role: 'rider',
    );

    final mockAuthResponse = AuthResponseModel(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      refreshTokenId: 'mock_refresh_token_id',
      user: mockUser,
    );

    // Save tokens
    await _storageService.saveTokens(
      accessToken: mockAuthResponse.accessToken,
      refreshToken: mockAuthResponse.refreshToken,
      refreshTokenId: mockAuthResponse.refreshTokenId,
    );

    // Save user data
    await _storageService.saveUserData(jsonEncode(mockAuthResponse.user.toJson()));

    return mockAuthResponse.user;
  }

  /// Register new rider
  Future<UserModel> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
  }) async {
    // MOCK IMPLEMENTATION
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final mockUser = UserModel(
      id: 'mock_user_456',
      email: email,
      phone: phone,
      fullName: fullName,
      role: 'rider',
    );

    // Save tokens (simulate auto-login after register)
    await _storageService.saveTokens(
      accessToken: 'mock_access_token_reg',
      refreshToken: 'mock_refresh_token_reg',
      refreshTokenId: 'mock_rt_id_reg',
    );

    await _storageService.saveUserData(jsonEncode(mockUser.toJson()));

    return mockUser;
  }

  /// Logout user
  Future<void> logout() async {
    // MOCK IMPLEMENTATION
    await _storageService.clearAll();
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    // MOCK IMPLEMENTATION
    // Just pretend we refreshed
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Get user profile
  Future<UserModel> getProfile() async {
    // MOCK IMPLEMENTATION
    final userData = await _storageService.getUserData();
    if (userData != null) {
      final json = jsonDecode(userData) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    }
    
    // Return dummy if no stored user
    return const UserModel(
      id: 'mock_user_profile',
      email: 'mock@vectra.com',
      phone: '9876543210',
      fullName: 'Mock Profile',
      role: 'rider',
    );
  }
}
