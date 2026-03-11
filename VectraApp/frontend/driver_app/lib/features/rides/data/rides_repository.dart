import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/socket/socket_service.dart';
import 'models/trip.dart';

/// Repository for ride/trip operations — connects to real backend APIs.
/// Accept/reject are handled via Socket.IO; status updates via REST.
class RidesRepository {
  final ApiClient _apiClient;
  final SocketService _socketService;

  RidesRepository(this._apiClient, this._socketService);

  /// Extract response payload, handling { data: ... } wrapper if present.
  Map<String, dynamic> _extractPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractListPayload(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map<String, dynamic> && inner['items'] is List) {
        return inner['items'] as List;
      }
      if (data['items'] is List) return data['items'] as List;
    }
    return const [];
  }

  /// Accept a ride offer via Socket.IO.
  /// Then fetch the trip details from REST to get full trip data.
  Future<Trip> acceptRide(String tripId) async {
    // 1. Emit socket event for real-time acceptance
    _socketService.acceptRide(tripId);
    _socketService.joinTrip(tripId);

    // 2. Fetch the trip to get full details
    final response = await _apiClient.get(ApiEndpoints.tripById(tripId));
    final payload = _extractPayload(response.data);
    return Trip.fromJson(payload);
  }

  /// Reject a ride offer via Socket.IO.
  Future<void> rejectRide(String tripId) async {
    _socketService.rejectRide(tripId);
  }

  /// Update trip status via REST: PATCH /api/v1/trips/:id/status
  Future<Trip> updateTripStatus(String tripId, TripStatus status) async {
    final response = await _apiClient.patch(
      ApiEndpoints.tripStatus(tripId),
      data: {'status': _tripStatusToBackendString(status)},
    );
    final payload = _extractPayload(response.data);
    return Trip.fromJson(payload);
  }

  /// Generate OTP when arriving: POST /api/v1/trips/:id/otp/generate
  Future<String> generateOtp(String tripId, String riderId) async {
    final response = await _apiClient.post(
      ApiEndpoints.tripOtpGenerate(tripId),
      data: {'riderId': riderId},
    );
    final payload = _extractPayload(response.data);
    return (payload['otp'] ?? '') as String;
  }

  /// Verify OTP to start trip: POST /api/v1/trips/:id/otp/verify
  Future<bool> verifyOtp(String tripId, String riderId, String otp) async {
    final response = await _apiClient.post(
      ApiEndpoints.tripOtpVerify(tripId),
      data: {'riderId': riderId, 'otp': otp},
    );
    final payload = _extractPayload(response.data);
    return (payload['success'] ?? false) as bool;
  }

  /// Start trip (after OTP verification): transition ARRIVING → IN_PROGRESS
  Future<Trip> startTrip(String tripId, String otp) async {
    // The OTP verification is done separately, so startTrip just updates status
    final response = await _apiClient.patch(
      ApiEndpoints.tripStatus(tripId),
      data: {'status': 'IN_PROGRESS'},
    );
    final payload = _extractPayload(response.data);
    return Trip.fromJson(payload);
  }

  /// Complete trip: transition IN_PROGRESS → COMPLETED
  Future<Trip> completeTrip(String tripId) async {
    final response = await _apiClient.patch(
      ApiEndpoints.tripStatus(tripId),
      data: {'status': 'COMPLETED'},
    );
    final payload = _extractPayload(response.data);
    // Leave the trip room
    _socketService.leaveTrip(tripId);
    return Trip.fromJson(payload);
  }

  /// Cancel trip with reason
  Future<void> cancelTrip(String tripId, String reason) async {
    await _apiClient.patch(
      ApiEndpoints.tripStatus(tripId),
      data: {'status': 'CANCELLED'},
    );
    _socketService.leaveTrip(tripId);
  }

  /// Get a specific trip: GET /api/v1/trips/:id
  Future<Trip?> getTrip(String tripId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.tripById(tripId));
      final payload = _extractPayload(response.data);
      if (payload.isNotEmpty) return Trip.fromJson(payload);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get active trip (first non-completed/cancelled trip for this driver)
  Future<Trip?> getActiveTrip() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.trips);
      final list = _extractListPayload(response.data);
      // Find first trip that is active (not completed or cancelled)
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final status = (item['status'] as String?)?.toUpperCase();
          if (status != null &&
              status != 'COMPLETED' &&
              status != 'CANCELLED') {
            return Trip.fromJson(item);
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get trip fare breakdown: GET /api/v1/trips/:id/fare
  Future<Map<String, dynamic>> getTripFare(String tripId) async {
    final response = await _apiClient.get(ApiEndpoints.tripFare(tripId));
    return _extractPayload(response.data);
  }

  /// Get trip history: GET /api/v1/trips
  Future<List<Trip>> getTripHistory({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.trips,
        queryParameters: {'page': page, 'limit': limit},
      );
      final list = _extractListPayload(response.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map(Trip.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Helper to convert TripStatus enum to backend UPPERCASE string.
String _tripStatusToBackendString(TripStatus status) {
  switch (status) {
    case TripStatus.requested:
      return 'REQUESTED';
    case TripStatus.assigned:
      return 'ASSIGNED';
    case TripStatus.arriving:
      return 'ARRIVING';
    case TripStatus.inProgress:
      return 'IN_PROGRESS';
    case TripStatus.completed:
      return 'COMPLETED';
    case TripStatus.cancelled:
      return 'CANCELLED';
  }
}
