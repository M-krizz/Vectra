import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/jwt_decoder.dart';
import 'models/auth_tokens.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  /// Send OTP to phone number
  Future<bool> sendOtp(OtpRequest request) async {
    try {
      // In production, this would call the actual API
      // For now, simulate a successful OTP send
      print('AuthRepository: Simulating API call...');
      await Future.delayed(const Duration(seconds: 1));
      print('AuthRepository: API call simulated');

      // Mock API call:
      // final response = await _apiClient.post(
      //   ApiEndpoints.sendOtp,
      //   data: request.toJson(),
      // );
      // return response.statusCode == 200;

      return true;
    } catch (e) {
      throw AuthError(message: 'Failed to send OTP. Please try again.');
    }
  }

  /// Verify OTP and get tokens
  Future<AuthTokens> verifyOtp(OtpVerification verification) async {
    try {
      // In production, this would call the actual API
      // For now, simulate a successful verification
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in production, use actual API:
      // final response = await _apiClient.post(
      //   ApiEndpoints.verifyOtp,
      //   data: verification.toJson(),
      // );
      // final tokens = AuthTokens.fromJson(response.data);

      // Mock tokens for development
      final mockTokens = AuthTokens(
        accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        role: UserRoles.driver,
        userId: 'driver_123',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      // Store tokens
      await _storage.saveTokens(
        accessToken: mockTokens.accessToken,
        refreshToken: mockTokens.refreshToken,
      );
      await _storage.saveUserRole(mockTokens.role);
      if (mockTokens.userId != null) {
        await _storage.saveUserId(mockTokens.userId!);
      }

      return mockTokens;
    } catch (e) {
      throw AuthError(message: 'Invalid OTP. Please try again.');
    }
  }

  /// Refresh access token
  Future<AuthTokens?> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return null;

      // In production, call the actual refresh API
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock new tokens
      final newTokens = AuthTokens(
        accessToken: 'refreshed_access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refreshed_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        role: UserRoles.driver,
        userId: await _storage.getUserId(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await _storage.saveTokens(
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
      );

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
