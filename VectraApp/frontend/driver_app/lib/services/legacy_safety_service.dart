import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';

class LegacySafetyService {
  LegacySafetyService._();

  static final SecureStorageService _storage = SecureStorageService();
  static final ApiClient _apiClient = ApiClient(storage: _storage);

  static Future<void> triggerSos({
    String? tripId,
    double? lat,
    double? lng,
  }) async {
    final payload = <String, dynamic>{
      'tripId': tripId,
      'lat': lat,
      'lng': lng,
    };
    payload.removeWhere((key, value) {
      if (value == null) return true;
      if (key == 'tripId' && value is String && value.isEmpty) return true;
      return false;
    });

    await _apiClient.post(
      ApiEndpoints.safetySos,
      data: payload,
    );
  }

  static Future<void> reportIncident({
    required String description,
    String? rideId,
  }) async {
    await _apiClient.post(
      ApiEndpoints.safetyIncidents,
      data: {
        'description': description,
        if (rideId != null && rideId.isNotEmpty) 'rideId': rideId,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getContacts() async {
    final response = await _apiClient.get(ApiEndpoints.safetyContacts);
    final data = response.data;
    final list = data is Map<String, dynamic>
        ? (data['data'] ?? data['items'] ?? data['contacts'])
        : data;
    if (list is List) {
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  static Future<void> addContact({
    required String name,
    required String phoneNumber,
    String? relationship,
  }) async {
    await _apiClient.post(
      ApiEndpoints.safetyContacts,
      data: {
        'name': name,
        'phoneNumber': phoneNumber,
        if (relationship != null && relationship.isNotEmpty)
          'relationship': relationship,
      },
    );
  }

  static Future<void> deleteContact(String id) async {
    await _apiClient.delete('${ApiEndpoints.safetyContacts}/$id');
  }
}