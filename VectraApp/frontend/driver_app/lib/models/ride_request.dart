import 'package:latlong2/latlong.dart';

enum RideStatus {
  idle,
  searching,
  requestReceived,
  goingToPickup,
  arrivedAtPickup,
  inProgress,
  completed,
}

class RideRequest {
  final String id;
  final String passengerName;
  final String passengerRating;
  final LatLng pickupLocation;
  final String pickupAddress;
  final LatLng dropLocation;
  final String dropAddress;
  final double fare;
  final String otp;
  final double distance;
  final String duration;
  final bool isPooling;

  RideRequest({
    required this.id,
    required this.passengerName,
    required this.passengerRating,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.dropLocation,
    required this.dropAddress,
    required this.fare,
    required this.otp,
    required this.distance,
    required this.duration,
    this.isPooling = false,
  });
}
