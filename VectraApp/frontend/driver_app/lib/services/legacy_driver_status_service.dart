import '../core/api/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/driver_status/data/driver_status_repository.dart';

class LegacyDriverStatusService {
  LegacyDriverStatusService._();

  static final SecureStorageService _storage = SecureStorageService();
  static final ApiClient _apiClient = ApiClient(storage: _storage);
  static final DriverStatusRepository _repository = DriverStatusRepository(
    apiClient: _apiClient,
    storage: _storage,
  );

  static Future<DriverProfile> getDriverProfile() {
    return _repository.getDriverProfile();
  }

  static Future<Map<String, dynamic>> validateOnlineEligibility() {
    return _repository.validateOnlineEligibility();
  }

  static Future<bool> updateOnlineStatus(bool online) {
    return _repository.updateStatus(online ? 'ONLINE' : 'OFFLINE');
  }
}