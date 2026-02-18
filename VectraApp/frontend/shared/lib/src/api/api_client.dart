import 'package:dio/dio.dart';
import '../storage/storage_service.dart';
import 'api_constants.dart';

/// Main API client using Dio with JWT interceptor
class ApiClient {
  late final Dio _dio;
  final StorageService _storageService;

  static ApiClient? _instance;

  ApiClient._internal(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            try {
              final refreshToken = await _storageService.getRefreshToken();
              final refreshTokenId = await _storageService.getRefreshTokenId();
              if (refreshToken != null && refreshTokenId != null) {
                final response = await Dio().post(
                  '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
                  data: {
                    'refreshToken': refreshToken,
                    'refreshTokenId': refreshTokenId,
                  },
                );
                final data = response.data as Map<String, dynamic>;
                await _storageService.saveTokens(
                  accessToken: data['accessToken'],
                  refreshToken: data['refreshToken'],
                  refreshTokenId: data['refreshTokenId'],
                );
                // Retry original request
                error.requestOptions.headers['Authorization'] =
                    'Bearer ${data['accessToken']}';
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              // Refresh failed, clear tokens
              await _storageService.clearAll();
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Get singleton instance
  static ApiClient getInstance(StorageService storageService) {
    _instance ??= ApiClient._internal(storageService);
    return _instance!;
  }

  Dio get dio => _dio;

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
