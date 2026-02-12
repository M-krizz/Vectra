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
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    _mockActiveTrip = Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      riderId: 'rider_001',
      riderName: 'Alice Wonderland',
      riderPhone: '+919876543210',
      riderRating: 4.8,
      pickupLocation: LatLng(12.9716, 77.5946),
      pickupAddress: 'MG Road Metro Station, Bangalore',
      dropoffLocation: LatLng(12.9352, 77.6245),
      dropoffAddress: 'Forum Mall, Koramangala',
      fare: 250.0,
      distance: 5.2,
      status: TripStatus.assigned,
      vehicleType: 'Sedan',
      otp: '1234',
      startedAt: null,
      completedAt: null,
    );
    return _mockActiveTrip!;
  }

  /// Reject a ride request
  Future<void> rejectRide(String rideRequestId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Update trip status
  Future<Trip> updateTripStatus(String tripId, TripStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_mockActiveTrip != null) {
      _mockActiveTrip = _mockActiveTrip!.copyWith(status: status);
      return _mockActiveTrip!;
    }
    throw Exception('No active trip found');
  }

  /// Start trip with OTP verification
  Future<Trip> startTrip(String tripId, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (otp != '1234') {
      throw Exception('Invalid OTP');
    }

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
    await Future.delayed(const Duration(seconds: 1));
    
    if (_mockActiveTrip != null) {
      _mockActiveTrip = _mockActiveTrip!.copyWith(
        status: TripStatus.completed,
        completedAt: DateTime.now(),
      );
      final completedTrip = _mockActiveTrip!;
      _mockActiveTrip = null; // Clear active trip
      return completedTrip;
    }
    throw Exception('No active trip found');
  }

  /// Cancel trip
  Future<void> cancelTrip(String tripId, String reason) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (_mockActiveTrip != null) {
      _mockActiveTrip = _mockActiveTrip!.copyWith(
        status: TripStatus.cancelled,
        cancellationReason: reason,
      );
      _mockActiveTrip = null;
    }
  }

  /// Get active trip
  Future<Trip?> getActiveTrip() async {
    return _mockActiveTrip;
  }

  /// Get trip history
  Future<List<Trip>> getTripHistory({int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(seconds: 1));
    // Return some mock history
    return [
      Trip(
        id: 'trip_history_1',
        riderId: 'rider_002',
        riderName: 'Bob Builder',
        pickupLocation: LatLng(12.9279, 77.6271),
        pickupAddress: 'Koramangala 5th Block',
        dropoffLocation: LatLng(12.9698, 77.7500),
        dropoffAddress: 'Whitefield',
        fare: 450.0,
        distance: 12.5,
        status: TripStatus.completed,
        vehicleType: 'Sedan',
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
