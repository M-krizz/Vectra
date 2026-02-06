import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Secure storage service for tokens and user data
class StorageService {
  static StorageService? _instance;
  final FlutterSecureStorage _storage;

  StorageService._internal()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  static StorageService getInstance() {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  /// Save auth tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String refreshTokenId,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
      _storage.write(
        key: AppConstants.refreshTokenIdKey,
        value: refreshTokenId,
      ),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  /// Get refresh token ID
  Future<String?> getRefreshTokenId() async {
    return await _storage.read(key: AppConstants.refreshTokenIdKey);
  }

  /// Save user data as JSON string
  Future<void> saveUserData(String userDataJson) async {
    await _storage.write(key: AppConstants.userDataKey, value: userDataJson);
  }

  /// Get user data JSON string
  Future<String?> getUserData() async {
    return await _storage.read(key: AppConstants.userDataKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Delete specific key
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Write arbitrary key-value
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read arbitrary key
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
}
