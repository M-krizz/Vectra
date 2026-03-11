import 'package:shared/shared.dart';
import '../models/emergency_contact_model.dart';

class SafetyRepository {
  final ApiClient _apiClient;

  SafetyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<EmergencyContactModel>> getContacts() async {
    final response = await _apiClient.get('/api/v1/safety/contacts');
    final list = response.data as List;
    return list.map((e) => EmergencyContactModel.fromJson(e)).toList();
  }

  Future<EmergencyContactModel> addContact({
    required String name,
    required String phoneNumber,
    String? relationship,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/safety/contacts',
      data: {
        'name': name,
        'phoneNumber': phoneNumber,
        ...?(relationship == null ? null : {'relationship': relationship}),
      },
    );
    return EmergencyContactModel.fromJson(response.data);
  }

  Future<void> deleteContact(String id) async {
    await _apiClient.delete('/api/v1/safety/contacts/$id');
  }
}
