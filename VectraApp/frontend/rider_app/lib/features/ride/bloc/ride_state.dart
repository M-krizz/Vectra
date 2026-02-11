part of 'ride_bloc.dart';

/// Driver information
class DriverInfo {
  final String id;
  final String name;
  final String phone;
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleColor;
  final double rating;
  final String photoUrl;
  final LatLng? location;

  const DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.rating,
    this.photoUrl = '',
    this.location,
  });

  DriverInfo copyWith({LatLng? location}) {
    return DriverInfo(
      id: id,
      name: name,
      phone: phone,
      vehicleNumber: vehicleNumber,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      rating: rating,
      photoUrl: photoUrl,
      location: location ?? this.location,
    );
  }
}

/// Ride booking status
enum RideStatus {
  initial, // No ride in progress
  selectingLocations, // User is selecting pickup/destination
  routeCalculated, // Route has been calculated, showing on map
  selectingVehicle, // User is selecting vehicle type
  searching, // Searching for a driver
  driverFound, // Driver has been found, en route to pickup
  arrived, // Driver has arrived at pickup
  inProgress, // Ride is in progress
  completed, // Ride completed
  cancelled, // Ride was cancelled
}

/// State for the Ride BLoC
class RideState {
  final RideStatus status;
  final PlaceModel? pickup;
  final PlaceModel? destination;
  final RouteModel? route;
  final List<VehicleOption> vehicleOptions;
  final VehicleOption? selectedVehicle;
  final DriverInfo? driver;
  final String? rideId;
  final double? finalFare;
  final String? error;
  final bool isLoading;
  final int? estimatedArrivalMinutes;
  final String? cancellationReason;
  final String rideType; // 'solo' or 'pool'

  const RideState({
    this.status = RideStatus.initial,
    this.pickup,
    this.destination,
    this.route,
    this.vehicleOptions = const [],
    this.selectedVehicle,
    this.driver,
    this.rideId,
    this.finalFare,
    this.error,
    this.isLoading = false,
    this.estimatedArrivalMinutes,
    this.cancellationReason,
    this.rideType = 'solo',
  });

  RideState copyWith({
    RideStatus? status,
    PlaceModel? pickup,
    PlaceModel? destination,
    RouteModel? route,
    List<VehicleOption>? vehicleOptions,
    VehicleOption? selectedVehicle,
    DriverInfo? driver,
    String? rideId,
    double? finalFare,
    String? error,
    bool? isLoading,
    int? estimatedArrivalMinutes,
    String? cancellationReason,
    String? rideType,
    bool clearPickup = false,
    bool clearDestination = false,
    bool clearRoute = false,
    bool clearError = false,
    bool clearDriver = false,
    bool clearSelectedVehicle = false,
  }) {
    return RideState(
      status: status ?? this.status,
      pickup: clearPickup ? null : (pickup ?? this.pickup),
      destination: clearDestination ? null : (destination ?? this.destination),
      route: clearRoute ? null : (route ?? this.route),
      vehicleOptions: vehicleOptions ?? this.vehicleOptions,
      selectedVehicle: clearSelectedVehicle
          ? null
          : (selectedVehicle ?? this.selectedVehicle),
      driver: clearDriver ? null : (driver ?? this.driver),
      rideId: rideId ?? this.rideId,
      finalFare: finalFare ?? this.finalFare,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rideType: rideType ?? this.rideType,
    );
  }

  /// Check if we have both pickup and destination
  bool get hasFullRoute => pickup != null && destination != null;

  /// Check if we can request a ride
  bool get canRequestRide =>
      route != null &&
      selectedVehicle != null &&
      status == RideStatus.selectingVehicle;

  @override
  String toString() =>
      'RideState(status: $status, pickup: ${pickup?.name}, destination: ${destination?.name})';
}
