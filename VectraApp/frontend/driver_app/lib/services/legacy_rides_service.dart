import 'dart:async';

import '../core/api/api_client.dart';
import '../core/socket/socket_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/rides/data/models/ride_request.dart' as feature;
import '../features/rides/data/models/trip.dart';
import '../features/rides/data/rides_repository.dart';
import '../models/ride_request.dart';

class LegacyRidesService {
  LegacyRidesService._();

  static final SecureStorageService _storage = SecureStorageService();
  static final ApiClient _apiClient = ApiClient(storage: _storage);
  static final SocketService _socketService = SocketService(storage: _storage);
  static final RidesRepository _ridesRepository =
      RidesRepository(_apiClient, _socketService);

  static StreamSubscription<Map<String, dynamic>>? _rideOfferSubscription;
  static StreamSubscription<Map<String, dynamic>>? _tripStatusSubscription;

  static Future<void> connect() async {
    if (_socketService.isConnected) return;
    await _socketService.connect();
    await _restoreActiveTripRoom();
  }

  static Future<void> _restoreActiveTripRoom() async {
    try {
      final activeTrip = await _ridesRepository.getActiveTrip();
      if (activeTrip == null) return;
      _socketService.joinTrip(activeTrip.id);
    } catch (_) {
      // Best effort only; active room restore failure should not block connect.
    }
  }

  static void disconnect() {
    _rideOfferSubscription?.cancel();
    _tripStatusSubscription?.cancel();
    _rideOfferSubscription = null;
    _tripStatusSubscription = null;
    _socketService.disconnect();
  }

  static void listenRideOffers(void Function(RideRequest request) onRideOffer) {
    _rideOfferSubscription?.cancel();
    _rideOfferSubscription = _socketService.rideOfferStream.listen((payload) {
      final request = _mapFeatureRideToLegacy(
        feature.RideRequest.fromJson(payload),
      );
      onRideOffer(request);
    });
  }

  static void listenTripStatusUpdates(
    void Function({required String tripId, required String status})
    onStatusUpdate,
  ) {
    _tripStatusSubscription?.cancel();
    _tripStatusSubscription = _socketService.tripStatusStream.listen((payload) {
      final tripId = _extractTripId(payload);
      final status = _extractStatus(payload);
      if (tripId.isEmpty || status.isEmpty) return;
      onStatusUpdate(tripId: tripId, status: status);
    });
  }

  static Future<void> acceptRide(String tripId) async {
    await _ridesRepository.acceptRide(tripId);
  }

  static Future<void> rejectRide(String tripId) async {
    await _ridesRepository.rejectRide(tripId);
  }

  static Future<bool> verifyTripOtp({
    required String tripId,
    required String riderId,
    required String otp,
  }) async {
    if (riderId.isEmpty) return false;
    return _ridesRepository.verifyOtp(tripId, riderId, otp);
  }

  static Future<void> startTrip(String tripId) async {
    await _ridesRepository.updateTripStatus(tripId, TripStatus.inProgress);
  }

  static Future<void> completeTrip(String tripId) async {
    await _ridesRepository.completeTrip(tripId);
  }

  static Future<void> cancelTrip({
    required String tripId,
    required String reason,
  }) async {
    await _ridesRepository.cancelTrip(tripId, reason);
  }

  static RideRequest _mapFeatureRideToLegacy(feature.RideRequest ride) {
    final mins = ride.estimatedDuration;
    return RideRequest(
      id: ride.id,
      riderId: ride.riderId,
      passengerName: ride.riderName,
      passengerRating: (ride.riderRating ?? 4.5).toStringAsFixed(1),
      pickupLocation: ride.pickupLocation,
      pickupAddress: ride.pickupAddress,
      dropLocation: ride.dropoffLocation,
      dropAddress: ride.dropoffAddress,
      fare: ride.estimatedFare,
      otp: '',
      distance: ride.estimatedDistance,
      duration: mins > 0 ? '$mins min' : 'N/A',
      isPooling: (ride.vehicleType ?? '').toLowerCase().contains('pool'),
    );
  }

  static String _extractTripId(Map<String, dynamic> payload) {
    if (payload['tripId'] is String) return payload['tripId'] as String;
    if (payload['id'] is String) return payload['id'] as String;
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      if (data['tripId'] is String) return data['tripId'] as String;
      if (data['id'] is String) return data['id'] as String;
    }
    return '';
  }

  static String _extractStatus(Map<String, dynamic> payload) {
    if (payload['status'] is String) return (payload['status'] as String).toUpperCase();
    final data = payload['data'];
    if (data is Map<String, dynamic> && data['status'] is String) {
      return (data['status'] as String).toUpperCase();
    }
    return '';
  }
}