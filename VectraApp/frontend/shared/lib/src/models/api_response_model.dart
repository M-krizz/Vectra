import 'package:equatable/equatable.dart';

/// Generic API response wrapper
class ApiResponseModel<T> extends Equatable {
  final String status;
  final T? data;
  final String? message;
  final String? error;

  const ApiResponseModel({
    required this.status,
    this.data,
    this.message,
    this.error,
  });

  bool get isSuccess =>
      status == 'ok' || status == 'created' || status == 'success';
  bool get isError => !isSuccess;

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponseModel(
      status: json['status'] as String? ?? 'ok',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }

  @override
  List<Object?> get props => [status, data, message, error];
}

/// Simple status response (for logout, deactivate, etc.)
class StatusResponseModel extends Equatable {
  final String status;
  final String? message;

  const StatusResponseModel({required this.status, this.message});

  bool get isSuccess => status == 'ok' || status == 'success';

  factory StatusResponseModel.fromJson(Map<String, dynamic> json) {
    return StatusResponseModel(
      status: json['status'] as String,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [status, message];
}
