import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/place_model.dart';
import '../repository/places_repository.dart';

part 'ride_event.dart';
part 'ride_state.dart';

/// BLoC for managing ride booking flow
class RideBloc extends Bloc<RideEvent, RideState> {
  final PlacesRepository _placesRepository;
  Timer? _driverSearchTimer;
  Timer? _driverMovementTimer;
  Timer? _rideProgressTimer;
  int _arrivalCountdown = 5; // Minutes until driver arrives

  RideBloc({required PlacesRepository placesRepository})
    : _placesRepository = placesRepository,
      super(const RideState()) {
    on<RidePickupSet>(_onPickupSet);
    on<RideDestinationSet>(_onDestinationSet);
    on<RidePickupCleared>(_onPickupCleared);
    on<RideDestinationCleared>(_onDestinationCleared);
    on<RideRouteRequested>(_onRouteRequested);
    on<RideCleared>(_onCleared);
    on<RideFareEstimateRequested>(_onFareEstimateRequested);
    on<RideTypeSelected>(_onRideTypeSelected);
    on<RideVehicleSelected>(_onVehicleSelected);
    on<RideRequested>(_onRideRequested);
    on<RideDriverFound>(_onDriverFound);
    on<RideDriverArrived>(_onDriverArrived);
    on<RideStarted>(_onRideStarted);
    on<RideDriverLocationUpdated>(_onDriverLocationUpdated);
    on<RideCompleted>(_onRideCompleted);
    on<RideCancelled>(_onRideCancelled);
    on<RideArrivalCountdownUpdated>(_onArrivalCountdownUpdated);
  }

  void _onPickupSet(RidePickupSet event, Emitter<RideState> emit) {
    emit(
      state.copyWith(
        pickup: event.pickup,
        status: RideStatus.selectingLocations,
        clearRoute: true,
        clearError: true,
      ),
    );

    // Automatically calculate route if destination is set
    if (state.destination != null) {
      add(const RideRouteRequested());
    }
  }

  void _onDestinationSet(RideDestinationSet event, Emitter<RideState> emit) {
    emit(
      state.copyWith(
        destination: event.destination,
        status: RideStatus.selectingLocations,
        clearRoute: true,
        clearError: true,
      ),
    );

    // Automatically calculate route if pickup is set
    if (state.pickup != null) {
      add(const RideRouteRequested());
    }
  }

  void _onPickupCleared(RidePickupCleared event, Emitter<RideState> emit) {
    emit(
      state.copyWith(
        clearPickup: true,
        clearRoute: true,
        status: RideStatus.selectingLocations,
      ),
    );
  }

  void _onDestinationCleared(
    RideDestinationCleared event,
    Emitter<RideState> emit,
  ) {
    emit(
      state.copyWith(
        clearDestination: true,
        clearRoute: true,
        status: RideStatus.selectingLocations,
      ),
    );
  }

  Future<void> _onRouteRequested(
    RideRouteRequested event,
    Emitter<RideState> emit,
  ) async {
    if (state.pickup == null || state.destination == null) {
      emit(state.copyWith(error: 'Please select both pickup and destination'));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final route = await _placesRepository.getRoute(
        state.pickup!,
        state.destination!,
      );

      emit(
        state.copyWith(
          route: route,
          status: RideStatus.routeCalculated,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Failed to calculate route: $e',
          isLoading: false,
        ),
      );
    }
  }

  void _onCleared(RideCleared event, Emitter<RideState> emit) {
    _driverSearchTimer?.cancel();
    _driverMovementTimer?.cancel();
    _rideProgressTimer?.cancel();
    emit(const RideState());
  }

  Future<void> _onFareEstimateRequested(
    RideFareEstimateRequested event,
    Emitter<RideState> emit,
  ) async {
    if (state.route == null) {
      emit(state.copyWith(error: 'Please calculate route first'));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate mock fare estimates based on distance
    final distanceKm = state.route!.distanceMeters / 1000;
    final baseFare = 30.0;
    final perKmRate = 12.0;

    final vehicleOptions = [
      VehicleOption(
        id: 'auto',
        name: 'Auto',
        description: '3-wheeler, budget friendly',
        imageUrl: 'assets/images/auto.png',
        fare: baseFare + (distanceKm * perKmRate * 0.7),
        etaMinutes: 3,
        capacity: 3,
      ),
      VehicleOption(
        id: 'mini',
        name: 'Mini',
        description: 'Compact cars, affordable',
        imageUrl: 'assets/images/mini.png',
        fare: baseFare + (distanceKm * perKmRate),
        etaMinutes: 5,
        capacity: 4,
      ),
      VehicleOption(
        id: 'sedan',
        name: 'Sedan',
        description: 'Comfortable sedans',
        imageUrl: 'assets/images/sedan.png',
        fare: baseFare + (distanceKm * perKmRate * 1.3),
        etaMinutes: 7,
        capacity: 4,
      ),
      VehicleOption(
        id: 'suv',
        name: 'SUV',
        description: 'Spacious SUVs for groups',
        imageUrl: 'assets/images/suv.png',
        fare: baseFare + (distanceKm * perKmRate * 1.7),
        etaMinutes: 10,
        capacity: 6,
      ),
    ];

    emit(
      state.copyWith(
        vehicleOptions: vehicleOptions,
        status: RideStatus.selectingVehicle,
        isLoading: false,
      ),
    );
  }

  void _onRideTypeSelected(RideTypeSelected event, Emitter<RideState> emit) {
    emit(state.copyWith(rideType: event.rideType, clearSelectedVehicle: true));
  }

  void _onVehicleSelected(RideVehicleSelected event, Emitter<RideState> emit) {
    emit(state.copyWith(selectedVehicle: event.vehicle));
  }

  Future<void> _onRideRequested(
    RideRequested event,
    Emitter<RideState> emit,
  ) async {
    if (state.selectedVehicle == null) {
      emit(state.copyWith(error: 'Please select a vehicle type'));
      return;
    }

    emit(
      state.copyWith(
        status: RideStatus.searching,
        isLoading: true,
        rideId: 'RIDE_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );

    // Simulate driver search (3-8 seconds)
    final searchDuration = Duration(seconds: 3 + Random().nextInt(5));
    _driverSearchTimer = Timer(searchDuration, () {
      // Create mock driver
      final mockDriver = DriverInfo(
        id: 'driver_${Random().nextInt(1000)}',
        name: _mockDriverNames[Random().nextInt(_mockDriverNames.length)],
        phone: '+91 98765 ${Random().nextInt(90000) + 10000}',
        vehicleNumber:
            'TN ${Random().nextInt(90) + 10} ${_randomLetters()} ${Random().nextInt(9000) + 1000}',
        vehicleModel:
            _mockVehicleModels[Random().nextInt(_mockVehicleModels.length)],
        vehicleColor: _mockColors[Random().nextInt(_mockColors.length)],
        rating: 4.0 + Random().nextDouble(),
        location: _getRandomNearbyLocation(state.pickup!.location!),
      );

      add(RideDriverFound(mockDriver));
    });
  }

  void _onDriverFound(RideDriverFound event, Emitter<RideState> emit) {
    _arrivalCountdown = 3 + Random().nextInt(3); // 3-5 minutes
    emit(
      state.copyWith(
        status: RideStatus.driverFound,
        driver: event.driver,
        isLoading: false,
        estimatedArrivalMinutes: _arrivalCountdown,
      ),
    );

    // Start simulating driver movement towards pickup
    _startDriverMovementSimulation();

    // Start countdown timer (every 10 seconds reduce by 1 minute for demo)
    _startArrivalCountdown();
  }

  void _startArrivalCountdown() {
    _rideProgressTimer?.cancel();
    _rideProgressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_arrivalCountdown > 1) {
        _arrivalCountdown--;
        add(RideArrivalCountdownUpdated(_arrivalCountdown));
      } else {
        timer.cancel();
        // Driver has arrived
        add(const RideDriverArrived());
      }
    });
  }

  void _onArrivalCountdownUpdated(
    RideArrivalCountdownUpdated event,
    Emitter<RideState> emit,
  ) {
    emit(state.copyWith(estimatedArrivalMinutes: event.minutes));
  }

  void _onDriverArrived(RideDriverArrived event, Emitter<RideState> emit) {
    _driverMovementTimer?.cancel();
    _rideProgressTimer?.cancel();
    emit(
      state.copyWith(status: RideStatus.arrived, estimatedArrivalMinutes: 0),
    );

    // After 5 seconds, auto-start the ride (simulating passenger boarding)
    _rideProgressTimer = Timer(const Duration(seconds: 5), () {
      add(const RideStarted());
    });
  }

  void _startDriverMovementSimulation() {
    // Move driver every 2 seconds towards pickup
    _driverMovementTimer?.cancel();
    _driverMovementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (state.driver?.location != null && state.pickup?.location != null) {
        final currentLoc = state.driver!.location!;
        final targetLoc = state.pickup!.location!;

        // Calculate distance to pickup
        final distance = _calculateDistance(currentLoc, targetLoc);

        if (distance < 50) {
          // Driver has arrived
          timer.cancel();
          // Transition to arrived state handled elsewhere
          return;
        }

        // Move driver closer (interpolate 10% towards target)
        final newLat =
            currentLoc.latitude +
            (targetLoc.latitude - currentLoc.latitude) * 0.15;
        final newLng =
            currentLoc.longitude +
            (targetLoc.longitude - currentLoc.longitude) * 0.15;

        add(RideDriverLocationUpdated(LatLng(newLat, newLng)));
      }
    });
  }

  void _onRideStarted(RideStarted event, Emitter<RideState> emit) {
    _driverMovementTimer?.cancel();
    _rideProgressTimer?.cancel();
    emit(state.copyWith(status: RideStatus.inProgress));

    // Simulate ride duration (15 seconds for demo, then complete)
    _rideProgressTimer = Timer(const Duration(seconds: 15), () {
      add(RideCompleted(state.selectedVehicle?.fare ?? 0));
    });
  }

  void _onDriverLocationUpdated(
    RideDriverLocationUpdated event,
    Emitter<RideState> emit,
  ) {
    if (state.driver != null) {
      emit(
        state.copyWith(
          driver: state.driver!.copyWith(location: event.location),
        ),
      );
    }
  }

  void _onRideCompleted(RideCompleted event, Emitter<RideState> emit) {
    _driverMovementTimer?.cancel();
    _driverSearchTimer?.cancel();
    emit(
      state.copyWith(status: RideStatus.completed, finalFare: event.finalFare),
    );
  }

  void _onRideCancelled(RideCancelled event, Emitter<RideState> emit) {
    _driverMovementTimer?.cancel();
    _driverSearchTimer?.cancel();
    emit(
      state.copyWith(
        status: RideStatus.cancelled,
        cancellationReason: event.reason,
        isLoading: false,
      ),
    );
  }

  // Helper methods
  LatLng _getRandomNearbyLocation(LatLng center) {
    final random = Random();
    final latOffset = (random.nextDouble() - 0.5) * 0.02; // ~1km offset
    final lngOffset = (random.nextDouble() - 0.5) * 0.02;
    return LatLng(center.latitude + latOffset, center.longitude + lngOffset);
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000;
    final double lat1Rad = start.latitude * pi / 180;
    final double lat2Rad = end.latitude * pi / 180;
    final double deltaLatRad = (end.latitude - start.latitude) * pi / 180;
    final double deltaLngRad = (end.longitude - start.longitude) * pi / 180;

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  String _randomLetters() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return String.fromCharCodes([
      letters.codeUnitAt(Random().nextInt(26)),
      letters.codeUnitAt(Random().nextInt(26)),
    ]);
  }

  static const _mockDriverNames = [
    'Rajesh Kumar',
    'Mohammed Salim',
    'Vijay Sharma',
    'Suresh Babu',
    'Arun Prakash',
    'Karthik Rajan',
    'Manoj Kumar',
    'Santosh Pillai',
  ];

  static const _mockVehicleModels = [
    'Maruti Swift',
    'Hyundai i20',
    'Honda City',
    'Toyota Etios',
    'Maruti Dzire',
    'Hyundai Xcent',
  ];

  static const _mockColors = [
    'White',
    'Silver',
    'Black',
    'Red',
    'Blue',
    'Grey',
  ];

  @override
  Future<void> close() {
    _driverSearchTimer?.cancel();
    _driverMovementTimer?.cancel();
    _rideProgressTimer?.cancel();
    return super.close();
  }
}
