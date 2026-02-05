import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  DioClient()
      : _dio = Dio(BaseOptions(
          baseUrl: 'http://localhost:3000/api/v1', // Update based on docker/device
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        )),
        _storage = const FlutterSecureStorage() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth header for public endpoints
        final isPublicEndpoint = options.path.startsWith('/auth/');
        if (!isPublicEndpoint) {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle token refresh logic here if 401
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
