import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'models/ride_request.dart';
import 'models/trip.dart';
import 'package:latlong2/latlong.dart';

class RidesRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  RidesRepository(this._apiClient, this._storage);

  // Mock in-memory state
  Trip? _mockActiveTrip;

  /// Accept a ride request
  Future<Trip> acceptRide(String rideRequestId) async {
    final response = await _apiClient.post(
      ApiEndpoints.acceptRide(rideRequestId),
      data: {},
    );
    _mockActiveTrip = Trip.fromJson(response.data);
    return _mockActiveTrip!;
  }

  /// Reject a ride request
  Future<void> rejectRide(String rideRequestId) async {
    await _apiClient.post(
      ApiEndpoints.rejectRide(rideRequestId),
      data: {},
    );
  }

  /// Update trip status (e.g., arrived)
  Future<Trip> updateTripStatus(String tripId, TripStatus status) async {
    // Backend doesn't have an explicit 'arrived' endpoint yet, so we just update local state if it's not a major transition
    if (status == TripStatus.started) {
       return startTrip(tripId, '1234'); // Placeholder
    } else if (status == TripStatus.completed) {
       return completeTrip(tripId);
    } else if (status == TripStatus.cancelled) {
       await cancelTrip(tripId, 'Cancelled');
       return _mockActiveTrip!.copyWith(status: TripStatus.cancelled);
    }
    
    // Otherwise just mock it for now
    if (_mockActiveTrip != null) {
      _mockActiveTrip = _mockActiveTrip!.copyWith(status: status);
      return _mockActiveTrip!;
    }
    throw Exception('No active trip found');
  }

  /// Start trip
  Future<Trip> startTrip(String tripId, String otp) async {
    await _apiClient.patch(
      ApiEndpoints.startTrip(tripId),
      data: {'otp': otp},
    );
    if (_mockActiveTrip != null) {
      _mockActiveTrip = _mockActiveTrip!.copyWith(
        status: TripStatus.started,
        startedAt: DateTime.now(),
      );
      return _mockActiveTrip!;
    }
    throw Exception('No active trip found');
  }

  /// Complete trip
  Future<Trip> completeTrip(String tripId) async {
    await _apiClient.patch(
      ApiEndpoints.completeTrip(tripId),
      data: {},
    );
    if (_mockActiveTrip != null) {
      final completedTrip = _mockActiveTrip!.copyWith(
        status: TripStatus.completed,
        completedAt: DateTime.now(),
      );
      _mockActiveTrip = null; // Clear active trip
      return completedTrip;
    }
    throw Exception('No active trip found');
  }

  /// Cancel trip
  Future<void> cancelTrip(String tripId, String reason) async {
    await _apiClient.patch(
      ApiEndpoints.cancelTrip(tripId),
      data: {'reason': reason},
    );
    _mockActiveTrip = null;
  }

  /// Get active trip
  Future<Trip?> getActiveTrip() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.activeTrip);
      if (response.data != null) {
        _mockActiveTrip = Trip.fromJson(response.data);
        return _mockActiveTrip;
      }
    } catch (e) {
      // Ignore
    }
    return _mockActiveTrip;
  }

  /// Get trip history
  Future<List<Trip>> getTripHistory({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.tripHistory,
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.data is List) {
        return (response.data as List).map((t) => Trip.fromJson(t)).toList();
      }
    } catch (e) {
      // Ignore and return empty
    }
    return [];
  }
}
