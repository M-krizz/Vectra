import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

/// Repository for authentication operations — OTP-only
class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository({
    required ApiClient apiClient,
    required StorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  // ──────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────

  /// Check if user is logged in (has valid access token)
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  /// Get current user from local storage
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

  /// Step 1 – Request OTP for a phone number or email address.
  /// Returns the raw response map (includes devOtp in dev mode).
  Future<Map<String, dynamic>> requestOtp({
    required String identifier,
    String channel = 'phone', // 'phone' or 'email'
  }) async {
    final response = await _apiClient.post(
      ApiConstants.requestOtp,
      data: {
        'channel': channel,
        'identifier': identifier,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Step 2 – Verify OTP and login/create user.
  /// On success, stores JWT tokens and user data locally and returns [UserModel].
  Future<UserModel> verifyOtpAndLogin({
    required String identifier,
    required String code,
    String roleHint = 'RIDER',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.verifyOtp,
      data: {
        'identifier': identifier,
        'code': code,
      },
      options: Options(headers: {'x-role-hint': roleHint}),
    );

    final data = response.data as Map<String, dynamic>;

    await _storageService.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      refreshTokenId: data['refreshTokenId'] as String,
    );

    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    await _storageService.saveUserData(jsonEncode(user.toJson()));

    return user;
  }

  /// Set the user's display name after first-time OTP login.
  Future<void> completeProfile({required String fullName}) async {
    await _apiClient.patch(
      ApiConstants.completeProfile,
      data: {'fullName': fullName},
    );
    // Update locally too
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updated = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        fullName: fullName,
        phone: currentUser.phone,
        role: currentUser.role,
      );
      await _storageService.saveUserData(jsonEncode(updated.toJson()));
    }
  }

  /// Update the user's profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? gender,
  }) async {
    final Map<String, dynamic> data = {};
    if (fullName != null) data['fullName'] = fullName;
    if (email != null) data['email'] = email;
    if (gender != null) data['gender'] = gender;

    await _apiClient.patch('/api/v1/profile', data: data);

    // Update locally
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updated = UserModel(
        id: currentUser.id,
        email: email ?? currentUser.email,
        fullName: fullName ?? currentUser.fullName,
        phone: currentUser.phone,
        role: currentUser.role,
        gender: gender ?? currentUser.gender,
        profilePicture: currentUser.profilePicture,
      );
      await _storageService.saveUserData(jsonEncode(updated.toJson()));
    }
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
    } catch (_) {
      // Ignore network errors on logout, clear local data anyway
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
}
