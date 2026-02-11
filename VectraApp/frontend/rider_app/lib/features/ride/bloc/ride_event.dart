part of 'ride_bloc.dart';

/// Events for the Ride BLoC
abstract class RideEvent {
  const RideEvent();
}

/// Set pickup location
class RidePickupSet extends RideEvent {
  final PlaceModel pickup;
  const RidePickupSet(this.pickup);
}

/// Set destination location
class RideDestinationSet extends RideEvent {
  final PlaceModel destination;
  const RideDestinationSet(this.destination);
}

/// Clear pickup location
class RidePickupCleared extends RideEvent {
  const RidePickupCleared();
}

/// Clear destination location
class RideDestinationCleared extends RideEvent {
  const RideDestinationCleared();
}

/// Calculate route between pickup and destination
class RideRouteRequested extends RideEvent {
  const RideRouteRequested();
}

/// Clear the entire ride state
class RideCleared extends RideEvent {
  const RideCleared();
}

/// Request fare estimates for the route
class RideFareEstimateRequested extends RideEvent {
  const RideFareEstimateRequested();
}

/// Select a vehicle option
class RideVehicleSelected extends RideEvent {
  final VehicleOption vehicle;
  const RideVehicleSelected(this.vehicle);
}

/// Select ride type (solo or pool)
class RideTypeSelected extends RideEvent {
  final String rideType; // 'solo' or 'pool'
  const RideTypeSelected(this.rideType);
}

/// Request a ride
class RideRequested extends RideEvent {
  const RideRequested();
}

/// Driver found for the ride
class RideDriverFound extends RideEvent {
  final DriverInfo driver;
  const RideDriverFound(this.driver);
}

/// Driver has arrived at pickup location
class RideDriverArrived extends RideEvent {
  const RideDriverArrived();
}

/// Update arrival countdown
class RideArrivalCountdownUpdated extends RideEvent {
  final int minutes;
  const RideArrivalCountdownUpdated(this.minutes);
}

/// Ride started (driver picked up the rider)
class RideStarted extends RideEvent {
  const RideStarted();
}

/// Update driver location during ride
class RideDriverLocationUpdated extends RideEvent {
  final LatLng location;
  const RideDriverLocationUpdated(this.location);
}

/// Ride completed
class RideCompleted extends RideEvent {
  final double finalFare;
  const RideCompleted(this.finalFare);
}

/// Ride cancelled
class RideCancelled extends RideEvent {
  final String reason;
  const RideCancelled(this.reason);
}
