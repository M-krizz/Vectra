import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for JWT tokens and sensitive data
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _driverStatusKey = 'driver_status';
  static const String _lastOnlineKey = 'last_online_timestamp';

  /// Save access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Save user role
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Save driver status
  Future<void> saveDriverStatus(String status) async {
    await _storage.write(key: _driverStatusKey, value: status);
  }

  /// Get driver status
  Future<String?> getDriverStatus() async {
    return await _storage.read(key: _driverStatusKey);
  }

  /// Save last online timestamp
  Future<void> saveLastOnlineTimestamp() async {
    await _storage.write(
      key: _lastOnlineKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Get last online timestamp
  Future<DateTime?> getLastOnlineTimestamp() async {
    final timestamp = await _storage.read(key: _lastOnlineKey);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Write a custom key-value pair
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a custom key
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a custom key
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}

// Provider for SecureStorageService
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
