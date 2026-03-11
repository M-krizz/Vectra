import '../core/api/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/models/auth_tokens.dart';

/// Lightweight auth bridge for legacy screens.
class LegacyAuthService {
  LegacyAuthService._();

  static final SecureStorageService _storage = SecureStorageService();
  static final ApiClient _apiClient = ApiClient(storage: _storage);
  static final AuthRepository _repository = AuthRepository(
    apiClient: _apiClient,
    storage: _storage,
  );

  static Future<OtpRequestResult> sendOtp({
    required String identifier,
    required String channel,
  }) {
    return _repository.sendOtp(
      OtpRequest(identifier: identifier, channel: channel),
    );
  }

  static Future<AuthTokens> verifyOtp({
    required String identifier,
    required String otp,
  }) {
    return _repository.verifyOtp(
      OtpVerification(identifier: identifier, otp: otp),
    );
  }
}