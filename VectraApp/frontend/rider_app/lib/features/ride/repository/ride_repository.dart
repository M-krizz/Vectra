import 'package:shared/shared.dart';

import '../models/place_model.dart';
import '../bloc/ride_bloc.dart';

class RideRepository {
  final ApiClient _apiClient;

  RideRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> createRideRequest({
    required PlaceModel pickup,
    required PlaceModel drop,
    required String rideType, // 'solo' | 'pool'
    String? vehicleType,      // 'auto', 'mini', 'sedan', 'suv', 'bike'
  }) async {
    final payload = {
      'pickupPoint': {
        'type': 'Point',
        'coordinates': [pickup.location!.longitude, pickup.location!.latitude],
      },
      'dropPoint': {
        'type': 'Point',
        'coordinates': [drop.location!.longitude, drop.location!.latitude],
      },
      'pickupAddress': pickup.name,
      'dropAddress': drop.name,
      'rideType': rideType.toUpperCase(),
    };

    if (vehicleType != null) {
      payload['vehicleType'] = vehicleType.toUpperCase();
    }

    final response = await _apiClient.post(
      ApiConstants.rideRequests,
      data: payload,
    );

    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelRideRequest(String rideId) async {
    await _apiClient.patch('${ApiConstants.rideRequests}/$rideId/cancel');
  }

  Future<Map<String, dynamic>?> getCurrentRideRequest() async {
    try {
      final response = await _apiClient.get(ApiConstants.currentRideRequest);
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Cancels a trip that has been accepted (rider cancellation endpoint)
  Future<Map<String, dynamic>> cancelByRider({required String tripId, required String reason}) async {
    final response = await _apiClient.post(
      ApiConstants.cancelByRider,
      data: {
        'tripId': tripId,
        'reason': reason,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get fare estimates from backend for all vehicle types
  Future<List<VehicleOption>> getFareEstimates({
    required double distanceMeters,
    required String rideType,
  }) async {
    final vehicleTypes = ['AUTO', 'BIKE', 'CAB'];
    final results = <VehicleOption>[];

    for (final vt in vehicleTypes) {
      final response = await _apiClient.post(
        ApiConstants.fareEstimate,
        data: {
          'vehicleType': vt,
          'rideType': rideType.toUpperCase(),
          'distanceMeters': distanceMeters,
        },
      );
      final data = response.data as Map<String, dynamic>;
      results.add(VehicleOption(
        id: vt.toLowerCase(),
        name: _vehicleDisplayName(vt),
        description: _vehicleDescription(vt),
        imageUrl: 'assets/images/${vt.toLowerCase()}.png',
        fare: (data['totalFare'] as num?)?.toDouble() ?? 0,
        etaMinutes: 5,
        capacity: vt == 'BIKE' ? 1 : (vt == 'AUTO' ? 3 : 4),
      ));
    }

    return results;
  }

  String _vehicleDisplayName(String type) {
    switch (type) {
      case 'AUTO': return 'Auto';
      case 'BIKE': return 'Bike';
      case 'CAB': return 'Cab';
      default: return type;
    }
  }

  String _vehicleDescription(String type) {
    switch (type) {
      case 'AUTO': return '3-wheeler, budget friendly';
      case 'BIKE': return 'Fast two-wheelers';
      case 'CAB': return 'Comfortable cars';
      default: return '';
    }
  }

  // ===== Pooling =====

  Future<List<PooledRiderRequest>> getPoolCandidates(String requestId) async {
    final response = await _apiClient.get(
      ApiConstants.poolingCandidates,
      queryParameters: {'requestId': requestId, 'radius': '2000'},
    );
    final list = response.data as List;
    return list.map((json) => PooledRiderRequest.fromJson(json)).toList();
  }

  Future<String?> finalizePool(List<String> riderIds) async {
    final response = await _apiClient.post(
      ApiConstants.poolingFinalize,
      data: {'riderIds': riderIds},
    );
    return response.data['tripId'] as String?;
  }

  Future<void> submitTripRating({
    required String tripId,
    required int rating,
    String? feedback,
    List<String>? tags,
  }) async {
    await _apiClient.post(
      ApiConstants.tripRating(tripId),
      data: {
        'rating': rating,
        if (feedback != null && feedback.trim().isNotEmpty)
          'feedback': feedback.trim(),
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );
  }
}
