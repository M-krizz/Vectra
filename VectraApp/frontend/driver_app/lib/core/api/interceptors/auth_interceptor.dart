import 'dart:async';
import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';
import '../api_endpoints.dart';

/// Auth interceptor that handles JWT token injection and refresh
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;

  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];
  Completer<void>? _refreshCompleter;

  AuthInterceptor({
    required Dio dio,
    required SecureStorageService storage,
  })  : _dio = dio,
        _storage = storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    // Get access token and add to header
    final accessToken = await _storage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - Token expired
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      // Skip refresh for auth endpoints
      if (_isAuthEndpoint(requestOptions.path)) {
        return handler.next(err);
      }

      // If already refreshing, queue this request
      if (_isRefreshing) {
        _pendingRequests.add(requestOptions);
        await _refreshCompleter?.future;
        return _retryRequest(requestOptions, handler);
      }

      // Start refresh flow
      _isRefreshing = true;
      _refreshCompleter = Completer<void>();

      try {
        final refreshed = await _refreshToken();

        if (refreshed) {
          // Complete pending requests
          _refreshCompleter?.complete();
          _isRefreshing = false;

          // Retry the original request
          return _retryRequest(requestOptions, handler);
        } else {
          // Refresh failed - logout user
          await _storage.clearTokens();
          _refreshCompleter?.complete();
          _isRefreshing = false;
          return handler.next(err);
        }
      } catch (e) {
        _refreshCompleter?.complete();
        _isRefreshing = false;
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.refreshToken}',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _retryRequest(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final accessToken = await _storage.getAccessToken();
      requestOptions.headers['Authorization'] = 'Bearer $accessToken';

      final response = await _dio.fetch(requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.reject(e as DioException);
    }
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/');
  }
}
