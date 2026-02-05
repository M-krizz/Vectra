import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(DioClient()));

class AuthRepository {
  final DioClient _client;

  AuthRepository(this._client);

  /// Returns the devOtp in development mode for testing
  Future<String?> requestOtp(String phone) async {
    final response = await _client.dio.post('/auth/request-otp', data: {
      'identifier': phone,
      'channel': 'phone',
    });
    // In dev mode, backend returns devOtp for testing
    return response.data['devOtp'];
  }

  Future<String> verifyOtp(String phone, String otp) async {
    final response = await _client.dio.post('/auth/verify-otp', data: {
      'identifier': phone,
      'code': otp,
    });
    // Assume response returns { accessToken: ... }
    // Ideally we parse a User model here.
    return response.data['accessToken']; 
  }
}
