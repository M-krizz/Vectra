import 'package:latlong2/latlong.dart';

/// Ride request model representing an incoming ride request
class RideRequest {
  final String id;
  final String riderId;
  final String riderName;
  final String? riderPhone;
  final double? riderRating;
  final LatLng pickupLocation;
  final String pickupAddress;
  final LatLng dropoffLocation;
  final String dropoffAddress;
  final double estimatedFare;
  final double estimatedDistance; // in km
  final int estimatedDuration; // in minutes
  final String vehicleType;
  final DateTime requestedAt;
  final String? specialInstructions;

  RideRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    this.riderPhone,
    this.riderRating,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.dropoffLocation,
    required this.dropoffAddress,
    required this.estimatedFare,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.vehicleType,
    required this.requestedAt,
    this.specialInstructions,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      riderPhone: json['riderPhone'] as String?,
      riderRating: (json['riderRating'] as num?)?.toDouble(),
      pickupLocation: LatLng(
        (json['pickupLocation']['lat'] as num).toDouble(),
        (json['pickupLocation']['lng'] as num).toDouble(),
      ),
      pickupAddress: json['pickupAddress'] as String,
      dropoffLocation: LatLng(
        (json['dropoffLocation']['lat'] as num).toDouble(),
        (json['dropoffLocation']['lng'] as num).toDouble(),
      ),
      dropoffAddress: json['dropoffAddress'] as String,
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      estimatedDistance: (json['estimatedDistance'] as num).toDouble(),
      estimatedDuration: json['estimatedDuration'] as int,
      vehicleType: json['vehicleType'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      specialInstructions: json['specialInstructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'riderRating': riderRating,
      'pickupLocation': {
        'lat': pickupLocation.latitude,
        'lng': pickupLocation.longitude,
      },
      'pickupAddress': pickupAddress,
      'dropoffLocation': {
        'lat': dropoffLocation.latitude,
        'lng': dropoffLocation.longitude,
      },
      'dropoffAddress': dropoffAddress,
      'estimatedFare': estimatedFare,
      'estimatedDistance': estimatedDistance,
      'estimatedDuration': estimatedDuration,
      'vehicleType': vehicleType,
      'requestedAt': requestedAt.toIso8601String(),
      'specialInstructions': specialInstructions,
    };
  }
}
