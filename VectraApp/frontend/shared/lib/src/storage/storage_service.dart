import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service for JWT tokens and user data.
///
/// On native platforms (Android/iOS): uses [FlutterSecureStorage] with
/// hardware-backed encryption.
///
/// On web (Chrome dev): uses [SharedPreferences] which maps to `localStorage`.
/// The `flutter_secure_storage` Web Crypto API is unavailable over plain HTTP,
/// so this fallback ensures the auth flow works in local development.
class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static StorageService? _instance;

  StorageService._internal();

  /// Get singleton instance
  static StorageService getInstance() {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _refreshTokenIdKey = 'refresh_token_id';
  static const String _userDataKey = 'user_data';

  // ─── Platform-aware read/write ───────────────────────────────────────────

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  Future<void> _deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_refreshTokenIdKey);
      await prefs.remove(_userDataKey);
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Save access, refresh tokens and refresh token ID
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String refreshTokenId,
  }) async {
    await Future.wait([
      _write(_accessTokenKey, accessToken),
      _write(_refreshTokenKey, refreshToken),
      _write(_refreshTokenIdKey, refreshTokenId),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async => await _read(_accessTokenKey);

  /// Get refresh token
  Future<String?> getRefreshToken() async => await _read(_refreshTokenKey);

  /// Get refresh token ID
  Future<String?> getRefreshTokenId() async => await _read(_refreshTokenIdKey);

  /// Save user data as JSON string
  Future<void> saveUserData(String userData) async {
    await _write(_userDataKey, userData);
  }

  /// Get user data as JSON string
  Future<String?> getUserData() async => await _read(_userDataKey);

  /// Check if user is logged in (has valid access token)
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored auth data (for logout)
  Future<void> clearAll() async => await _deleteAll();

  /// Write a custom key-value pair
  Future<void> write(String key, String value) async => await _write(key, value);

  /// Read a custom key
  Future<String?> read(String key) async => await _read(key);

  /// Delete a custom key
  Future<void> delete(String key) async => await _delete(key);
}
