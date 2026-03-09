import 'package:dio/dio.dart';
import 'package:shared/shared.dart';
import '../models/place_model.dart';
import 'dart:convert';

class RideRepository {
  final ApiClient apiClient;

  RideRepository({required this.apiClient});

  Future<Map<String, dynamic>> requestRide({
    required PlaceModel pickup,
    required PlaceModel destination,
    required String rideType,
    required String? vehicleId,
    required double estimatedFare,
    required double distanceMeters,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.rideRequests,
        data: {
          'pickupLocation': {
            'lat': pickup.location?.latitude,
            'lng': pickup.location?.longitude,
            'address': pickup.address,
          },
          'dropoffLocation': {
            'lat': destination.location?.latitude,
            'lng': destination.location?.longitude,
            'address': destination.address,
          },
          'rideType': rideType,
          'vehicleType': vehicleId,
          'estimatedFare': estimatedFare,
          'distance': distanceMeters,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to request ride');
      }
      throw Exception('Network error occurred');
    }
  }

  Future<void> cancelRide(String rideId, String reason) async {
    try {
      await apiClient.post(
        '${ApiConstants.rideRequests}/$rideId/cancel',
        data: {'reason': reason},
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to cancel ride');
      }
      throw Exception('Network error occurred');
    }
  }
}
