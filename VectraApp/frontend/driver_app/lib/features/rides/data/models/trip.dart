import 'package:latlong2/latlong.dart';

/// Trip status enum — matches backend TripStatus exactly (UPPERCASE).
enum TripStatus {
  requested,
  assigned,
  arriving,
  inProgress,
  completed,
  cancelled,
}

/// Maps backend UPPERCASE status string to enum.
TripStatus _parseTripStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'REQUESTED':
      return TripStatus.requested;
    case 'ASSIGNED':
      return TripStatus.assigned;
    case 'ARRIVING':
      return TripStatus.arriving;
    case 'IN_PROGRESS':
      return TripStatus.inProgress;
    case 'COMPLETED':
      return TripStatus.completed;
    case 'CANCELLED':
      return TripStatus.cancelled;
    default:
      return TripStatus.requested;
  }
}

/// Maps enum to backend UPPERCASE string.
String _tripStatusToBackend(TripStatus status) {
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

/// Extracts LatLng from a GeoJSON Point: { type: "Point", coordinates: [lng, lat] }
LatLng _geoPointToLatLng(dynamic point) {
  if (point is Map) {
    // GeoJSON format: coordinates are [longitude, latitude]
    final coords = point['coordinates'];
    if (coords is List && coords.length >= 2) {
      return LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );
    }
    // Fallback: plain { lat, lng } format
    if (point['lat'] != null && point['lng'] != null) {
      return LatLng(
        (point['lat'] as num).toDouble(),
        (point['lng'] as num).toDouble(),
      );
    }
  }
  return LatLng(0, 0);
}

/// Trip model representing an active or completed trip.
/// Parses the backend TripEntity shape with nested tripRiders and GeoPoints.
class Trip {
  final String id;
  final String? driverUserId;
  final String riderId;
  final String riderName;
  final String? riderPhone;
  final double? riderRating;
  final LatLng pickupLocation;
  final String pickupAddress;
  final LatLng dropoffLocation;
  final String dropoffAddress;
  final double fare;
  final double distance;
  final TripStatus status;
  final String? otp;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? vehicleType;
  final List<LatLng>? route;
  final String? cancellationReason;

  Trip({
    required this.id,
    this.driverUserId,
    required this.riderId,
    required this.riderName,
    this.riderPhone,
    this.riderRating,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.dropoffLocation,
    required this.dropoffAddress,
    required this.fare,
    required this.distance,
    required this.status,
    this.otp,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.vehicleType,
    this.route,
    this.cancellationReason,
  });

  /// Parses backend TripEntity with nested relations.
  /// Backend shape:
  /// {
  ///   id, driverUserId, status (UPPERCASE), assignedAt, startAt, endAt,
  ///   driver: { id, fullName, phone, ... },
  ///   tripRiders: [{ riderUserId, pickupPoint (GeoJSON), dropPoint (GeoJSON),
  ///                   fareShare, rider: { id, fullName, phone, ... } }]
  /// }
  factory Trip.fromJson(Map<String, dynamic> json) {
    // Extract first rider from tripRiders relation
    final tripRiders = json['tripRiders'] as List?;
    final firstRider =
        (tripRiders != null && tripRiders.isNotEmpty) ? tripRiders[0] as Map<String, dynamic> : null;
    final riderUser = firstRider?['rider'] as Map<String, dynamic>?;

    // Pickup / drop from tripRider's GeoJSON Points
    LatLng pickup = LatLng(0, 0);
    LatLng dropoff = LatLng(0, 0);
    if (firstRider != null) {
      pickup = _geoPointToLatLng(firstRider['pickupPoint'] ?? firstRider['pickup_point']);
      dropoff = _geoPointToLatLng(firstRider['dropPoint'] ?? firstRider['drop_point']);
    }

    // Fallback flat fields for enriched ride_offered payloads
    if (pickup.latitude == 0 && json['pickupLocation'] != null) {
      pickup = _geoPointToLatLng(json['pickupLocation']);
    }
    if (dropoff.latitude == 0 && json['dropoffLocation'] != null) {
      dropoff = _geoPointToLatLng(json['dropoffLocation']);
    }

    // Fare from tripRider.fareShare or top-level
    final fare = (firstRider?['fareShare'] as num?)?.toDouble() ??
        (json['fare'] as num?)?.toDouble() ??
        0.0;

    return Trip(
      id: (json['id'] ?? json['tripId'] ?? '') as String,
      driverUserId: json['driverUserId'] as String?,
      riderId: (firstRider?['riderUserId'] ?? json['riderId'] ?? '') as String,
      riderName: (riderUser?['fullName'] ?? riderUser?['full_name'] ?? json['riderName'] ?? 'Rider') as String,
      riderPhone: (riderUser?['phone'] ?? json['riderPhone']) as String?,
      riderRating: (json['riderRating'] as num?)?.toDouble(),
      pickupLocation: pickup,
      pickupAddress: (json['pickupAddress'] ?? '') as String,
      dropoffLocation: dropoff,
      dropoffAddress: (json['dropoffAddress'] ?? '') as String,
      fare: fare,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      status: _parseTripStatus(json['status'] as String?),
      otp: json['otp'] as String?,
      assignedAt: json['assignedAt'] != null ? DateTime.tryParse(json['assignedAt'].toString()) : null,
      startedAt: (json['startAt'] ?? json['startedAt']) != null
          ? DateTime.tryParse((json['startAt'] ?? json['startedAt']).toString())
          : null,
      completedAt: (json['endAt'] ?? json['completedAt']) != null
          ? DateTime.tryParse((json['endAt'] ?? json['completedAt']).toString())
          : null,
      vehicleType: json['vehicleType'] as String?,
      route: json['route'] != null
          ? (json['route'] as List)
              .map((point) => LatLng(
                    (point['lat'] as num).toDouble(),
                    (point['lng'] as num).toDouble(),
                  ))
              .toList()
          : null,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverUserId': driverUserId,
      'status': _tripStatusToBackend(status),
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
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
      'fare': fare,
      'distance': distance,
      'otp': otp,
      'assignedAt': assignedAt?.toIso8601String(),
      'startAt': startedAt?.toIso8601String(),
      'endAt': completedAt?.toIso8601String(),
      'vehicleType': vehicleType,
    };
  }

  Trip copyWith({
    String? id,
    String? driverUserId,
    String? riderId,
    String? riderName,
    String? riderPhone,
    double? riderRating,
    LatLng? pickupLocation,
    String? pickupAddress,
    LatLng? dropoffLocation,
    String? dropoffAddress,
    double? fare,
    double? distance,
    TripStatus? status,
    String? otp,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? vehicleType,
    List<LatLng>? route,
    String? cancellationReason,
  }) {
    return Trip(
      id: id ?? this.id,
      driverUserId: driverUserId ?? this.driverUserId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      riderRating: riderRating ?? this.riderRating,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      otp: otp ?? this.otp,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      vehicleType: vehicleType ?? this.vehicleType,
      route: route ?? this.route,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
