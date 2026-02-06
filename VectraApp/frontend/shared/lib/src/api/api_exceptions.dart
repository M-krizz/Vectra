/// API Exceptions for Vectra apps
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String? message})
    : super(message: message ?? 'Unauthorized access', statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException({String? message})
    : super(message: message ?? 'Access forbidden', statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException({String? message})
    : super(message: message ?? 'Resource not found', statusCode: 404);
}

class BadRequestException extends ApiException {
  BadRequestException({String? message, dynamic data})
    : super(message: message ?? 'Bad request', statusCode: 400, data: data);
}

class ServerException extends ApiException {
  ServerException({String? message})
    : super(message: message ?? 'Server error', statusCode: 500);
}

class NetworkException extends ApiException {
  NetworkException({String? message})
    : super(message: message ?? 'Network error. Please check your connection.');
}

class TimeoutException extends ApiException {
  TimeoutException({String? message})
    : super(message: message ?? 'Request timed out. Please try again.');
}
