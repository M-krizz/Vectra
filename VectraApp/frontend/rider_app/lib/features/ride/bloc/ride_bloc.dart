import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';
import '../repository/places_repository.dart';
import '../repository/ride_repository.dart';
import '../services/trip_socket_service.dart';
import 'package:shared/shared.dart' show StorageService;

part 'ride_event.dart';
part 'ride_state.dart';

/// BLoC for managing ride booking flow
class RideBloc extends Bloc<RideEvent, RideState> {
  final PlacesRepository _placesRepository;
  final RideRepository _rideRepository;
  final TripSocketService _tripSocketService;
  final StorageService _storageService;

  StreamSubscription? _socketStatusSubscription;
  StreamSubscription? _socketLocationSubscription;
  StreamSubscription? _socketOtpSubscription;
  StreamSubscription? _socketPoolTimeoutSubscription;

  Timer? _driverSearchTimer;
  Timer? _rideProgressTimer;

  RideBloc({
    required PlacesRepository placesRepository,
    required RideRepository rideRepository,
    required TripSocketService tripSocketService,
    required StorageService storageService,
  })
    : _placesRepository = placesRepository,
      _rideRepository = rideRepository,
      _tripSocketService = tripSocketService,
      _storageService = storageService,
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
    on<RidePooledRequestsRequested>(_onPooledRequestsRequested);
    on<RidePooledRequestSelected>(_onPooledRequestSelected);
    on<RidePooledAutoConfirmed>(_onPooledAutoConfirmed);
    on<RideOTPGenerated>(_onOTPGenerated);
    on<RideOTPVerified>(_onOTPVerified);
    on<RideNoDriversFound>(_onNoDriversFound);
    on<RideSocketStatusReceived>(_onSocketStatusReceived);
    on<RideSocketLocationReceived>(_onSocketLocationReceived);
    on<RideCancellationReasonUpdated>(_onCancellationReasonUpdated);
    on<RidePoolTimedOut>(_onPoolTimedOut);

    // Subscribe to socket events
    _socketStatusSubscription = _tripSocketService.tripStatusStream.listen((event) {
      add(RideSocketStatusReceived(tripId: event.tripId, status: event.status, payload: event.payload));
    });
    _socketLocationSubscription = _tripSocketService.locationStream.listen((event) {
      add(RideSocketLocationReceived(tripId: event.tripId, lat: event.lat, lng: event.lng, etaSeconds: event.etaSeconds));
    });
    _socketOtpSubscription = _tripSocketService.otpStream.listen((data) {
      final otp = data['otp']?.toString();
      if (otp != null) {
        add(RideOTPGenerated(otp));
      }
    });
    _socketPoolTimeoutSubscription = _tripSocketService.poolTimeoutStream.listen((data) {
      add(RidePoolTimedOut(
        requestId: data['requestId']?.toString() ?? '',
        message: data['message']?.toString() ?? 'No pool match found. Please try again.',
      ));
    });
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
    _rideProgressTimer?.cancel();
    if (state.rideId != null) {
      _tripSocketService.leaveTripRoom(state.rideId!);
    }
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

    try {
      final distanceMeters = state.route!.distanceMeters;
      final estimates = await _rideRepository.getFareEstimates(
        distanceMeters: distanceMeters,
        rideType: state.rideType,
      );

      emit(
        state.copyWith(
          vehicleOptions: estimates,
          status: RideStatus.selectingVehicle,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Failed to get fare estimates: $e',
          isLoading: false,
        ),
      );
    }
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
    if (state.selectedVehicle == null || state.pickup == null || state.destination == null) {
      emit(state.copyWith(error: 'Missing ride details to request trip'));
      return;
    }

    emit(
      state.copyWith(
        status: RideStatus.searching,
        isLoading: true,
      ),
    );

    try {
      final response = await _rideRepository.createRideRequest(
        pickup: state.pickup!,
        drop: state.destination!,
        rideType: state.rideType,
        vehicleType: state.selectedVehicle?.id,
      );

      final rideId = response['id'] ?? response['tripId'] ?? response['_id'];
      final estimatedFare = (response['estimatedFare'] as num?)?.toDouble();

      final token = await _storageService.getAccessToken();
      if (token != null) {
        _tripSocketService.connect(token: token);
        _tripSocketService.joinTripRoom(rideId);
      }

      emit(state.copyWith(rideId: rideId, estimatedFare: estimatedFare));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to request ride: $e',
        status: RideStatus.selectingVehicle,
        isLoading: false,
      ));
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
  }

  void _onArrivalCountdownUpdated(
    RideArrivalCountdownUpdated event,
    Emitter<RideState> emit,
  ) {
    emit(state.copyWith(estimatedArrivalMinutes: event.minutes));
  }

  void _onDriverArrived(RideDriverArrived event, Emitter<RideState> emit) {
    emit(state.copyWith(status: RideStatus.arrived));
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
    _driverSearchTimer?.cancel();
    if (state.rideId != null) {
      _tripSocketService.leaveTripRoom(state.rideId!);
    }
    emit(
      state.copyWith(status: RideStatus.completed, finalFare: event.finalFare),
    );
  }

  Future<void> _onRideCancelled(RideCancelled event, Emitter<RideState> emit) async {
    _driverSearchTimer?.cancel();
    
    if (state.rideId != null) {
      try {
        if (state.status == RideStatus.searching) {
          await _rideRepository.cancelRideRequest(state.rideId!);
        } else {
          await _rideRepository.cancelByRider(tripId: state.rideId!, reason: event.reason);
        }
      } catch (e) {
        // Continue cancellation locally even if API fails
      }
      _tripSocketService.leaveTripRoom(state.rideId!);
    }

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
    _driverSearchTimer?.cancel();
    _rideProgressTimer?.cancel();
    _socketStatusSubscription?.cancel();
    _socketLocationSubscription?.cancel();
    _socketOtpSubscription?.cancel();
    _socketPoolTimeoutSubscription?.cancel();
    return super.close();
  }

  // ── New event handlers ────────────────────────────────────────────────

  void _onNoDriversFound(RideNoDriversFound event, Emitter<RideState> emit) {
    _driverSearchTimer?.cancel();
    emit(state.copyWith(
      status: RideStatus.noDriversFound,
      isLoading: false,
    ));
  }

  /// Pool search window expired — reset state so the user can try again.
  void _onPoolTimedOut(RidePoolTimedOut event, Emitter<RideState> emit) {
    _driverSearchTimer?.cancel();
    emit(state.copyWith(
      status: RideStatus.noDriversFound, // reuse this state to surface the dialog
      isLoading: false,
      error: event.message,
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
        DriverInfo? driver;
        if (event.payload.containsKey('driver')) {
          final d = event.payload['driver'];
          driver = DriverInfo(
            id: d['id']?.toString() ?? '',
            name: d['name']?.toString() ?? 'Driver',
            phone: d['phone']?.toString() ?? '',
            vehicleNumber: d['vehicleNumber']?.toString() ?? '',
            vehicleModel: d['vehicleModel']?.toString() ?? '',
            vehicleColor: d['vehicleColor']?.toString() ?? '',
            rating: (d['rating'] as num?)?.toDouble() ?? 4.5,
            location: LatLng(
              (d['lat'] as num?)?.toDouble() ?? state.pickup?.location?.latitude ?? 0.0,
              (d['lng'] as num?)?.toDouble() ?? state.pickup?.location?.longitude ?? 0.0,
            ),
          );
        }
        
        final distance = (event.payload['distance'] as num?)?.toDouble();
        final duration = (event.payload['duration'] as num?)?.toInt();

        emit(state.copyWith(
          status: RideStatus.driverFound,
          driver: driver,
          tripDistanceKm: distance,
          tripDurationMinutes: duration,
        ));
        break;
      case 'ARRIVING':
        emit(state.copyWith(status: RideStatus.arrived));
        break;
      case 'IN_PROGRESS':
        emit(state.copyWith(status: RideStatus.inProgress));
        break;
      case 'COMPLETED':
        final fare = (event.payload['fare'] as num?)?.toDouble()
            ?? state.selectedVehicle?.fare
            ?? 0;
        emit(state.copyWith(status: RideStatus.completed, finalFare: fare));
        break;
      case 'CANCELLED':
        final reason = event.payload['reason']?.toString() ?? 'Trip cancelled';
        emit(state.copyWith(
          status: RideStatus.cancelled,
          cancellationReason: reason,
        ));
        break;
      case 'OTP_VERIFIED':
        emit(state.copyWith(otpVerified: true));
        break;
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
    if (state.rideId == null) return;
    
    emit(state.copyWith(isLoading: true));

    try {
      final candidates = await _rideRepository.getPoolCandidates(state.rideId!);
      emit(state.copyWith(
        pooledRequests: candidates,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load pool candidates: $e',
        isLoading: false,
      ));
    }
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

  /// Handle OTP received from backend via socket (trip_otp event)
  Future<void> _onOTPGenerated(
    RideOTPGenerated event,
    Emitter<RideState> emit,
  ) async {
    emit(state.copyWith(riderOtp: event.otp));
  }

  /// Handle OTP verified by driver (otp_verified socket event)
  Future<void> _onOTPVerified(
    RideOTPVerified event,
    Emitter<RideState> emit,
  ) async {
    emit(state.copyWith(otpVerified: true));
  }
}
