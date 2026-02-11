import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/rides_repository.dart';
import '../../data/models/ride_request.dart';
import '../../data/models/trip.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

// Repository provider
final ridesRepositoryProvider = Provider<RidesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return RidesRepository(apiClient, storage);
});

// Ride request state
class RideRequestState {
  final RideRequest? currentRequest;
  final bool isLoading;
  final String? error;

  RideRequestState({
    this.currentRequest,
    this.isLoading = false,
    this.error,
  });

  bool get hasActiveRequest => currentRequest != null;

  RideRequestState copyWith({
    RideRequest? currentRequest,
    bool? isLoading,
    String? error,
    bool clearRequest = false,
  }) {
    return RideRequestState(
      currentRequest: clearRequest ? null : (currentRequest ?? this.currentRequest),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Ride request notifier
class RideRequestNotifier extends StateNotifier<RideRequestState> {
  final RidesRepository _repository;

  RideRequestNotifier(this._repository) : super(RideRequestState());

  void setRideRequest(RideRequest request) {
    state = state.copyWith(currentRequest: request);
  }

  Future<void> acceptCurrentRequest() async {
    if (state.currentRequest == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final trip = await _repository.acceptRide(state.currentRequest!.id);
      state = state.copyWith(isLoading: false, clearRequest: true);
      // Trip will be handled by ActiveTripNotifier
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to accept ride: ${e.toString()}',
      );
    }
  }

  Future<void> rejectCurrentRequest() async {
    if (state.currentRequest == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await _repository.rejectRide(state.currentRequest!.id);
      state = state.copyWith(isLoading: false, clearRequest: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reject ride: ${e.toString()}',
      );
    }
  }

  void clearRequest() {
    state = state.copyWith(clearRequest: true);
  }
}

// Ride request provider
final rideRequestProvider =
    StateNotifierProvider<RideRequestNotifier, RideRequestState>((ref) {
  final repository = ref.watch(ridesRepositoryProvider);
  return RideRequestNotifier(repository);
});

// Active trip state
class ActiveTripState {
  final Trip? trip;
  final bool isLoading;
  final String? error;

  ActiveTripState({
    this.trip,
    this.isLoading = false,
    this.error,
  });

  bool get hasActiveTrip => trip != null;

  ActiveTripState copyWith({
    Trip? trip,
    bool? isLoading,
    String? error,
    bool clearTrip = false,
  }) {
    return ActiveTripState(
      trip: clearTrip ? null : (trip ?? this.trip),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Active trip notifier
class ActiveTripNotifier extends StateNotifier<ActiveTripState> {
  final RidesRepository _repository;

  ActiveTripNotifier(this._repository) : super(ActiveTripState()) {
    _loadActiveTrip();
  }

  Future<void> _loadActiveTrip() async {
    state = state.copyWith(isLoading: true);
    try {
      final trip = await _repository.getActiveTrip();
      state = state.copyWith(trip: trip, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setTrip(Trip trip) {
    state = state.copyWith(trip: trip);
  }

  Future<void> updateStatus(TripStatus status) async {
    if (state.trip == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final updatedTrip = await _repository.updateTripStatus(
        state.trip!.id,
        status,
      );
      state = state.copyWith(trip: updatedTrip, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update status: ${e.toString()}',
      );
    }
  }

  Future<void> startTrip(String otp) async {
    if (state.trip == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final updatedTrip = await _repository.startTrip(state.trip!.id, otp);
      state = state.copyWith(trip: updatedTrip, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid OTP or failed to start trip',
      );
    }
  }

  Future<void> completeTrip() async {
    if (state.trip == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final completedTrip = await _repository.completeTrip(state.trip!.id);
      state = state.copyWith(trip: completedTrip, isLoading: false);
      // Clear trip after a delay
      Future.delayed(const Duration(seconds: 2), () {
        state = state.copyWith(clearTrip: true);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete trip: ${e.toString()}',
      );
    }
  }

  Future<void> cancelTrip(String reason) async {
    if (state.trip == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await _repository.cancelTrip(state.trip!.id, reason);
      state = state.copyWith(isLoading: false, clearTrip: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel trip: ${e.toString()}',
      );
    }
  }

  void clearTrip() {
    state = state.copyWith(clearTrip: true);
  }
}

// Active trip provider
final activeTripProvider =
    StateNotifierProvider<ActiveTripNotifier, ActiveTripState>((ref) {
  final repository = ref.watch(ridesRepositoryProvider);
  return ActiveTripNotifier(repository);
});
