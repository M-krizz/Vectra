/// Base API exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException(message: $message, statusCode: $statusCode)';
}

/// 401 Unauthorized exception
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    String message = 'Unauthorized',
    int? statusCode = 401,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

/// 404 Not Found exception
class NotFoundException extends ApiException {
  const NotFoundException({
    String message = 'Not Found',
    int? statusCode = 404,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

/// 400 Bad Request exception
class BadRequestException extends ApiException {
  const BadRequestException({
    String message = 'Bad Request',
    int? statusCode = 400,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

/// 500 Server Error exception
class ServerException extends ApiException {
  const ServerException({
    String message = 'Server Error',
    int? statusCode = 500,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}
