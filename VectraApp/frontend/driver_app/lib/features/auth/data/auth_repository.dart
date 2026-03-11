import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/jwt_decoder.dart';
import 'models/auth_tokens.dart';

class OtpRequestResult {
  final bool success;
  final String? devOtp;

  const OtpRequestResult({
    required this.success,
    this.devOtp,
  });
}

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  /// Send OTP to phone number or email (identifier)
  Future<OtpRequestResult> sendOtp(OtpRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.requestOtp,
        data: {
          'identifier': request.identifier,
          'channel': request.channel,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      return OtpRequestResult(
        success: response.statusCode == 200 || response.statusCode == 201,
        devOtp: data?['devOtp'] as String?,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw AuthError(message: msg ?? 'Failed to send OTP. Please try again.');
    } catch (e) {
      throw AuthError(message: 'Failed to send OTP. Please try again.');
    }
  }

  /// Verify OTP and get tokens
  Future<AuthTokens> verifyOtp(OtpVerification verification) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'identifier': verification.identifier,
          'code': verification.otp,
        },
        options: Options(headers: {'x-role-hint': 'DRIVER'}),
      );
      
      final data = response.data;
      final tokens = AuthTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        role: data['user']['role'] ?? 'DRIVER',
        userId: data['user']['id'],
        isNewUser: (data['user']?['fullName'] as String?)?.trim().isEmpty ?? true,
      );

      // Store tokens
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      final refreshTokenId = data['refreshTokenId'] as String?;
      if (refreshTokenId != null && refreshTokenId.isNotEmpty) {
        await _storage.saveRefreshTokenId(refreshTokenId);
      }
      await _storage.saveUserRole(tokens.role);
      if (tokens.userId != null) {
        await _storage.saveUserId(tokens.userId!);
      }

      return tokens;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw AuthError(message: msg ?? 'Invalid OTP. Please try again.');
    } catch (e) {
      throw AuthError(message: 'Invalid OTP. Please try again.');
    }
  }

  /// Refresh access token
  Future<AuthTokens?> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      final refreshTokenId = await _storage.getRefreshTokenId();
      if (refreshToken == null) return null;
      if (refreshTokenId == null || refreshTokenId.isEmpty) return null;

      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {'x-refresh-token-id': refreshTokenId},
        ),
      );

      final data = response.data;
      final newTokens = AuthTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        role: data['user']?['role'] ?? 'DRIVER',
        userId: await _storage.getUserId(),
      );

      await _storage.saveTokens(
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
      );
      final newRefreshTokenId = data['refreshTokenId'] as String?;
      if (newRefreshTokenId != null && newRefreshTokenId.isNotEmpty) {
        await _storage.saveRefreshTokenId(newRefreshTokenId);
      }

      return newTokens;
    } catch (e) {
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // In production, call logout API to invalidate tokens
      // await _apiClient.post(ApiEndpoints.logout);

      await _storage.clearTokens();
      await _storage.clearAll();
    } catch (e) {
      // Still clear local tokens even if API call fails
      await _storage.clearTokens();
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _storage.isAuthenticated();
  }

  /// Get current user role
  Future<String?> getUserRole() async {
    return await _storage.getUserRole();
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    return await _storage.getUserId();
  }

  /// Validate driver role
  Future<bool> isDriverRole() async {
    final role = await getUserRole();
    return role == UserRoles.driver;
  }
}

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepository(apiClient: apiClient, storage: storage);
});
