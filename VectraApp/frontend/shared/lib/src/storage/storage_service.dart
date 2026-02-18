import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for JWT tokens and user data
class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
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

  /// Save access, refresh tokens and refresh token ID
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String refreshTokenId,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _refreshTokenIdKey, value: refreshTokenId),
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

  /// Get refresh token ID
  Future<String?> getRefreshTokenId() async {
    return await _storage.read(key: _refreshTokenIdKey);
  }

  /// Save user data as JSON string
  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userDataKey, value: userData);
  }

  /// Get user data as JSON string
  Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  /// Check if user is logged in (has valid access token)
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data (for logout)
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
