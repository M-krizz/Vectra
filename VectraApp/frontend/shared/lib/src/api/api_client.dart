import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import 'api_exceptions.dart';

/// API Client singleton for making HTTP requests
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final StorageService _storageService;

  ApiClient._internal(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_storageService, _dio));
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  static ApiClient getInstance(StorageService storageService) {
    _instance ??= ApiClient._internal(storageService);
    return _instance!;
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to ApiException
  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badResponse:
        return _handleResponseError(e.response);
      case DioExceptionType.cancel:
        return ApiException(message: 'Request cancelled');
      default:
        return ApiException(
          message: e.message ?? 'An unexpected error occurred',
        );
    }
  }

  /// Handle HTTP response errors
  ApiException _handleResponseError(Response? response) {
    if (response == null) {
      return ApiException(message: 'No response from server');
    }

    final statusCode = response.statusCode;
    final data = response.data;
    String message = 'An error occurred';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message: message, data: data);
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 500:
      case 502:
      case 503:
        return ServerException(message: message);
      default:
        return ApiException(message: message, statusCode: statusCode);
    }
  }
}

/// Auth interceptor for adding tokens and handling token refresh
class _AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._storageService, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    final publicEndpoints = [
      ApiConstants.login,
      ApiConstants.registerRider,
      ApiConstants.registerDriver,
      ApiConstants.generateOtp,
      ApiConstants.verifyOtp,
      ApiConstants.refreshToken,
    ];

    final isPublic = publicEndpoints.any((e) => options.path.contains(e));

    if (!isPublic) {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await _storageService.getRefreshToken();
        final refreshTokenId = await _storageService.getRefreshTokenId();

        if (refreshToken != null && refreshTokenId != null) {
          final response = await _dio.post(
            ApiConstants.refreshToken,
            data: {
              'refreshToken': refreshToken,
              'refreshTokenId': refreshTokenId,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data;
            await _storageService.saveTokens(
              accessToken: data['accessToken'],
              refreshToken: data['refreshToken'],
              refreshTokenId: data['refreshTokenId'],
            );

            // Retry the original request
            err.requestOptions.headers['Authorization'] =
                'Bearer ${data['accessToken']}';
            final retryResponse = await _dio.fetch(err.requestOptions);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        }
      } catch (_) {
        // Token refresh failed, clear tokens
        await _storageService.clearAll();
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }
}
