import 'package:latlong2/latlong.dart';

/// Extracts LatLng from a GeoJSON Point or plain { lat, lng } map.
LatLng _parseLocation(dynamic point) {
  if (point is Map) {
    final coords = point['coordinates'];
    if (coords is List && coords.length >= 2) {
      return LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );
    }
    if (point['lat'] != null && point['lng'] != null) {
      return LatLng(
        (point['lat'] as num).toDouble(),
        (point['lng'] as num).toDouble(),
      );
    }
  }
  return LatLng(0, 0);
}

/// Ride request model representing an incoming ride offer from the matching service.
/// The backend `ride_offered` event sends an enriched payload with trip + rider details.
class RideRequest {
  final String id; // tripId
  final String riderId;
  final String riderName;
  final String? riderPhone;
  final double? riderRating;
  final LatLng pickupLocation;
  final String pickupAddress;
  final LatLng dropoffLocation;
  final String dropoffAddress;
  final double estimatedFare;
  final double estimatedDistance;
  final int estimatedDuration;
  final String? vehicleType;
  final DateTime requestedAt;

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
    this.vehicleType,
    required this.requestedAt,
  });

  /// Parses the enriched ride_offered payload from backend.
  /// Backend sends: { tripId, riderName, riderPhone, pickupPoint (GeoJSON),
  ///   dropPoint (GeoJSON), pickupAddress, dropoffAddress, estimatedFare,
  ///   estimatedDistance, estimatedDuration, vehicleType, createdAt }
  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: (json['tripId'] ?? json['id'] ?? '') as String,
      riderId: (json['riderId'] ?? json['riderUserId'] ?? '') as String,
      riderName: (json['riderName'] ?? 'Rider') as String,
      riderPhone: json['riderPhone'] as String?,
      riderRating: (json['riderRating'] as num?)?.toDouble(),
      pickupLocation: _parseLocation(json['pickupPoint'] ?? json['pickupLocation']),
      pickupAddress: (json['pickupAddress'] ?? '') as String,
      dropoffLocation: _parseLocation(json['dropPoint'] ?? json['dropoffLocation']),
      dropoffAddress: (json['dropoffAddress'] ?? '') as String,
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      estimatedDistance: (json['estimatedDistance'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: (json['estimatedDuration'] as num?)?.toInt() ?? 0,
      vehicleType: json['vehicleType'] as String?,
      requestedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['requestedAt'] != null
              ? DateTime.tryParse(json['requestedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': id,
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
    };
  }
}
