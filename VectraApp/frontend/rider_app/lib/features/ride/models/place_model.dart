import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model representing a place/location
class PlaceModel {
  final String placeId;
  final String name;
  final String address;
  final LatLng? location;

  const PlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    this.location,
  });

  PlaceModel copyWith({
    String? placeId,
    String? name,
    String? address,
    LatLng? location,
  }) {
    return PlaceModel(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
    );
  }

  @override
  String toString() =>
      'PlaceModel(placeId: $placeId, name: $name, address: $address, location: $location)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceModel &&
          runtimeType == other.runtimeType &&
          placeId == other.placeId;

  @override
  int get hashCode => placeId.hashCode;
}

/// Model for a ride route
class RouteModel {
  final PlaceModel pickup;
  final PlaceModel destination;
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final int durationSeconds;
  final String distanceText;
  final String durationText;

  const RouteModel({
    required this.pickup,
    required this.destination,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
  });

  @override
  String toString() =>
      'RouteModel(pickup: ${pickup.name}, destination: ${destination.name}, distance: $distanceText, duration: $durationText)';
}

/// Model for vehicle options with fare
class VehicleOption {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double fare;
  final int etaMinutes;
  final int capacity;

  const VehicleOption({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.fare,
    required this.etaMinutes,
    required this.capacity,
  });

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    return VehicleOption(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      fare: (json['fare'] as num).toDouble(),
      etaMinutes: json['etaMinutes'] as int,
      capacity: json['capacity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'fare': fare,
    'etaMinutes': etaMinutes,
    'capacity': capacity,
  };
}
