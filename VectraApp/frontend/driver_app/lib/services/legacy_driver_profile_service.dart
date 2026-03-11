import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';

class LegacyDriverProfileService {
  LegacyDriverProfileService._();

  static final SecureStorageService _storage = SecureStorageService();
  static final ApiClient _apiClient = ApiClient(storage: _storage);

  static Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _apiClient.get(ApiEndpoints.driverProfile);
    final data = (response.data ?? {}) as Map<String, dynamic>;

    final user = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    return {
      'fullName': user['fullName'] ?? '',
      'phone': user['phone'] ?? '',
      'email': user['email'] ?? '',
      'licenseFileUrl': data['licenseFileUrl'],
      'rcFileUrl': data['rcFileUrl'],
      'status': data['status'],
    };
  }

  static Future<void> updateFullName(String fullName) async {
    await _apiClient.patch(
      ApiEndpoints.completeProfile,
      data: {'fullName': fullName},
    );
  }
}
