import 'package:latlong2/latlong.dart';

/// Trip status enum
enum TripStatus {
  assigned,
  enRoute,
  arrived,
  started,
  completed,
  cancelled,
}

/// Trip model representing an active or completed trip
class Trip {
  final String id;
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
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String vehicleType;
  final List<LatLng>? route;
  final String? cancellationReason;

  Trip({
    required this.id,
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
    this.startedAt,
    this.completedAt,
    required this.vehicleType,
    this.route,
    this.cancellationReason,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
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
      fare: (json['fare'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      status: TripStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TripStatus.assigned,
      ),
      otp: json['otp'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      vehicleType: json['vehicleType'] as String,
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
      'fare': fare,
      'distance': distance,
      'status': status.name,
      'otp': otp,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'vehicleType': vehicleType,
      'route': route
          ?.map((point) => {
                'lat': point.latitude,
                'lng': point.longitude,
              })
          .toList(),
      'cancellationReason': cancellationReason,
    };
  }

  Trip copyWith({
    String? id,
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
    DateTime? startedAt,
    DateTime? completedAt,
    String? vehicleType,
    List<LatLng>? route,
    String? cancellationReason,
  }) {
    return Trip(
      id: id ?? this.id,
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
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      vehicleType: vehicleType ?? this.vehicleType,
      route: route ?? this.route,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
