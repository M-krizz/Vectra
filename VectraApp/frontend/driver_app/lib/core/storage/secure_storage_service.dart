import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service for JWT tokens and sensitive data.
/// On web, falls back to SharedPreferences (localStorage) because
/// flutter_secure_storage uses SubtleCrypto which is unavailable or
/// unreliable on non-HTTPS origins. On Android/iOS, uses the native
/// secure keychain/keystore via flutter_secure_storage.
class SecureStorageService {
  static const FlutterSecureStorage _nativeStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Cached SharedPreferences instance for web.
  static SharedPreferences? _webPrefs;

  Future<SharedPreferences> _getWebPrefs() async {
    return _webPrefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await _getWebPrefs();
      await prefs.setString(key, value);
    } else {
      await _nativeStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await _getWebPrefs();
      return prefs.getString(key);
    } else {
      return _nativeStorage.read(key: key);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await _getWebPrefs();
      await prefs.remove(key);
    } else {
      await _nativeStorage.delete(key: key);
    }
  }

  Future<void> _deleteAll() async {
    if (kIsWeb) {
      final prefs = await _getWebPrefs();
      await prefs.clear();
    } else {
      await _nativeStorage.deleteAll();
    }
  }

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _refreshTokenIdKey = 'refresh_token_id';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _driverStatusKey = 'driver_status';
  static const String _lastOnlineKey = 'last_online_timestamp';

  /// Save access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _write(_accessTokenKey, accessToken);
    await _write(_refreshTokenKey, refreshToken);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return _read(_accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return _read(_refreshTokenKey);
  }

  /// Save refresh token ID used by backend refresh rotation.
  Future<void> saveRefreshTokenId(String refreshTokenId) async {
    await _write(_refreshTokenIdKey, refreshTokenId);
  }

  /// Get refresh token ID.
  Future<String?> getRefreshTokenId() async {
    return _read(_refreshTokenIdKey);
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    await _delete(_accessTokenKey);
    await _delete(_refreshTokenKey);
    await _delete(_refreshTokenIdKey);
  }

  /// Save user role
  Future<void> saveUserRole(String role) async {
    await _write(_userRoleKey, role);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    return _read(_userRoleKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _write(_userIdKey, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return _read(_userIdKey);
  }

  /// Save driver status
  Future<void> saveDriverStatus(String status) async {
    await _write(_driverStatusKey, status);
  }

  /// Get driver status
  Future<String?> getDriverStatus() async {
    return _read(_driverStatusKey);
  }

  /// Save last online timestamp
  Future<void> saveLastOnlineTimestamp() async {
    await _write(_lastOnlineKey, DateTime.now().toIso8601String());
  }

  /// Get last online timestamp
  Future<DateTime?> getLastOnlineTimestamp() async {
    final timestamp = await _read(_lastOnlineKey);
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
    await _deleteAll();
  }

  /// Write a custom key-value pair
  Future<void> write(String key, String value) async {
    await _write(key, value);
  }

  /// Read a custom key
  Future<String?> read(String key) async {
    return _read(key);
  }

  /// Delete a custom key
  Future<void> delete(String key) async {
    await _delete(key);
  }
}

// Provider for SecureStorageService
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
