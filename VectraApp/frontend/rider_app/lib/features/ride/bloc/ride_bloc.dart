import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/place_model.dart';
import '../repository/places_repository.dart';
import '../repository/ride_repository.dart';
import '../../../core/socket/socket_service.dart';

part 'ride_event.dart';
part 'ride_state.dart';

/// BLoC for managing ride booking flow
class RideBloc extends Bloc<RideEvent, RideState> {
  final PlacesRepository _placesRepository;
  final RideRepository _rideRepository;
  final SocketService _socketService;
  StreamSubscription? _rideStatusSubscription;
  StreamSubscription? _driverLocationSubscription;

  RideBloc({
    required PlacesRepository placesRepository,
    required RideRepository rideRepository,
    required SocketService socketService,
  }) : _placesRepository = placesRepository,
       _rideRepository = rideRepository,
       _socketService = socketService,
       super(const RideState()) {
    
    // Listen to real backend socket events
    _rideStatusSubscription = _socketService.rideStatusStream.listen((data) {
      if (data['status'] == 'ARRIVING') {
        final driverData = data['data']?['driver'] ?? {};
        final driver = DriverInfo(
          id: driverData['id'] ?? 'driver_real',
          name: driverData['name'] ?? 'Assigned Driver',
          phone: driverData['phone'] ?? '+91 9999999999',
          vehicleNumber: driverData['vehicleNumber'] ?? 'TN 01 A 1234',
          vehicleModel: driverData['vehicleModel'] ?? 'Sedan',
          vehicleColor: driverData['vehicleColor'] ?? 'White',
          rating: 4.8,
          location: LatLng(12.9716, 77.5946), // default temp
        );
        add(RideDriverFound(driver));
      } else if (data['status'] == 'ARRIVED') {
        add(const RideDriverArrived());
      } else if (data['status'] == 'COMPLETED') {
        add(RideCompleted(state.selectedVehicle?.fare ?? 0));
      } else if (data['status'] == 'CANCELLED') {
        add(const RideCancelled('Cancelled by driver'));
      }
    });

    _driverLocationSubscription = _socketService.driverLocationStream.listen((data) {
      if (data['latitude'] != null && data['longitude'] != null) {
        add(RideDriverLocationUpdated(LatLng(data['latitude'], data['longitude'])));
      }
    });
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
    on<RideStarted>(_onRideStarted);
    on<RideDriverLocationUpdated>(_onDriverLocationUpdated);
    on<RideCompleted>(_onRideCompleted);
    on<RideCancelled>(_onRideCancelled);
    on<RidePooledRequestsRequested>(_onPooledRequestsRequested);
    on<RidePooledRequestSelected>(_onPooledRequestSelected);
    on<RidePooledAutoConfirmed>(_onPooledAutoConfirmed);
    on<RideOTPGenerated>(_onOTPGenerated);
    on<RideOTPVerified>(_onOTPVerified);
    on<RideNoDriversFound>(_onNoDriversFound);
    on<RideSocketStatusReceived>(_onSocketStatusReceived);
    on<RideSocketLocationReceived>(_onSocketLocationReceived);
    on<RideCancellationReasonUpdated>(_onCancellationReasonUpdated);
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
      VehicleOption(
        id: 'bike',
        name: 'Bike',
        description: 'Fast two-wheelers',
        imageUrl: 'assets/images/bike.png',
        fare: baseFare + (distanceKm * perKmRate * 0.5),
        etaMinutes: 2,
        capacity: 1,
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
      ),
    );

    try {
      final res = await _rideRepository.requestRide(
        pickup: state.pickup!,
        destination: state.destination!,
        rideType: state.rideType,
        vehicleId: state.selectedVehicle?.id,
        estimatedFare: state.selectedVehicle?.fare ?? 0.0,
        distanceMeters: state.route?.distanceMeters.toDouble() ?? 0.0,
      );
      
      emit(state.copyWith(rideId: res['rideId'] ?? 'RIDE_${DateTime.now().millisecondsSinceEpoch}'));
      // Driver search will now be answered via socket event (RideDriverFound)
    } catch (e) {
      emit(state.copyWith(error: 'Failed: $e', status: RideStatus.selectingVehicle, isLoading: false));
    }
  }

  void _onDriverFound(RideDriverFound event, Emitter<RideState> emit) {
    emit(
      state.copyWith(
        status: RideStatus.driverFound,
        driver: event.driver,
        isLoading: false,
      ),
    );

    // Simulation timers removed here. Real-time updates come via sockets.
  }

  void _onRideStarted(RideStarted event, Emitter<RideState> emit) {
    emit(state.copyWith(status: RideStatus.inProgress));
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
    emit(
      state.copyWith(status: RideStatus.completed, finalFare: event.finalFare),
    );
  }

  void _onRideCancelled(RideCancelled event, Emitter<RideState> emit) {
    emit(
      state.copyWith(
        status: RideStatus.cancelled,
        cancellationReason: event.reason,
        isLoading: false,
      ),
    );
  }

  void _onCancellationReasonUpdated(
    RideCancellationReasonUpdated event,
    Emitter<RideState> emit,
  ) {
    emit(state.copyWith(cancellationReason: event.reason));
  }

  @override
  Future<void> close() {
    _rideStatusSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    return super.close();
  }

  // ── New event handlers ────────────────────────────────────────────────

  void _onNoDriversFound(RideNoDriversFound event, Emitter<RideState> emit) {
    emit(state.copyWith(
      status: RideStatus.noDriversFound,
      isLoading: false,
    ));
  }

  /// Maps backend status strings (from WebSocket) to RideBloc events.
  /// This is the socket → BLoC bridge: the UI layer subscribes to RideBloc
  /// state and the socket service calls rideBloc.add(RideSocketStatusReceived()).
  void _onSocketStatusReceived(
    RideSocketStatusReceived event,
    Emitter<RideState> emit,
  ) {
    // Only process events for the current trip
    if (event.tripId != state.rideId && state.rideId != null) return;

    switch (event.status.toUpperCase()) {
      case 'ASSIGNED':
        // Driver info may come from payload in production
        emit(state.copyWith(status: RideStatus.driverFound));
      case 'ARRIVING':
        emit(state.copyWith(status: RideStatus.arrived));
      case 'IN_PROGRESS':
        emit(state.copyWith(status: RideStatus.inProgress));
      case 'COMPLETED':
        final fare = (event.payload['fare'] as num?)?.toDouble()
            ?? state.selectedVehicle?.fare
            ?? 0;
        emit(state.copyWith(status: RideStatus.completed, finalFare: fare));
      case 'CANCELLED':
        final reason = event.payload['reason']?.toString() ?? 'Trip cancelled';
        emit(state.copyWith(
          status: RideStatus.cancelled,
          cancellationReason: reason,
        ));
      default:
        break;
    }
  }

  void _onSocketLocationReceived(
    RideSocketLocationReceived event,
    Emitter<RideState> emit,
  ) {
    if (state.driver == null) return;
    final eta = event.etaSeconds != null
        ? (event.etaSeconds! / 60).round()
        : state.estimatedArrivalMinutes;
    emit(state.copyWith(
      driver: state.driver!.copyWith(
        location: LatLng(event.lat, event.lng),
      ),
      estimatedArrivalMinutes: eta,
    ));
  }

  /// Load available pooled rider requests
  Future<void> _onPooledRequestsRequested(
    RidePooledRequestsRequested event,
    Emitter<RideState> emit,
  ) async {
    // Simulate fetching pooled requests from API
    // In real app, call API to get available pooled riders
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock pooled requests
    final mockRequests = [
      PooledRiderRequest(
        id: 'pool_1',
        riderId: 'rider_2',
        riderName: 'Priya Sharma',
        riderPhone: '+91 9876543210',
        rating: 4.8,
        photoUrl: '',
        pickup:
            state.pickup ??
            const PlaceModel(
              placeId: '',
              name: 'Unknown',
              address: '',
              location: null,
            ),
        destination:
            state.destination ??
            const PlaceModel(
              placeId: '',
              name: 'Destination',
              address: '',
              location: null,
            ),
      ),
      PooledRiderRequest(
        id: 'pool_2',
        riderId: 'rider_3',
        riderName: 'Rajesh Patel',
        riderPhone: '+91 9765432109',
        rating: 4.6,
        photoUrl: '',
        pickup:
            state.pickup ??
            const PlaceModel(
              placeId: '',
              name: 'Pickup',
              address: '',
              location: null,
            ),
        destination:
            state.destination ??
            const PlaceModel(
              placeId: '',
              name: 'Destination',
              address: '',
              location: null,
            ),
      ),
    ];

    // Randomly return 0-2 pooled requests (empty list means no pool available)
    final random = Random();
    final requestsToShow = random.nextBool()
        ? mockRequests.cast<PooledRiderRequest>()
        : <PooledRiderRequest>[];

    emit(state.copyWith(pooledRequests: requestsToShow));
  }

  /// Handle pooled request selection
  Future<void> _onPooledRequestSelected(
    RidePooledRequestSelected event,
    Emitter<RideState> emit,
  ) async {
    emit(state.copyWith(selectedPooledRequest: event.request));
  }

  /// Auto-confirm pool ride when no pooled requests available
  Future<void> _onPooledAutoConfirmed(
    RidePooledAutoConfirmed event,
    Emitter<RideState> emit,
  ) async {
    if (state.pooledRequests.isEmpty) {
      // No pooled riders available, proceed as solo
      emit(state.copyWith(rideType: 'solo', clearPooledRequests: true));
      // Continue with ride request
      add(const RideRequested());
    }
  }

  /// Handle OTP generation for rider
  Future<void> _onOTPGenerated(
    RideOTPGenerated event,
    Emitter<RideState> emit,
  ) async {
    // OTP is generated when driver arrives, just update state
    if (state.riderOtp != null) {
      emit(state.copyWith(riderOtp: state.riderOtp));
    }
  }

  /// Handle driver OTP verification
  Future<void> _onOTPVerified(
    RideOTPVerified event,
    Emitter<RideState> emit,
  ) async {
    // Verify that the OTP entered by driver matches the rider's OTP
    if (state.riderOtp != null && event.otp == state.riderOtp) {
      // OTP verified successfully
      emit(state.copyWith(otpVerified: true));

      // Start the ride after OTP verification
      Future.delayed(const Duration(milliseconds: 500), () {
        add(const RideStarted());
      });
    } else {
      // Invalid OTP - show error on driver app (this would be handled in driver app)
      // For rider, just emit without changes as error is shown on driver side
      emit(state);
    }
  }
}
