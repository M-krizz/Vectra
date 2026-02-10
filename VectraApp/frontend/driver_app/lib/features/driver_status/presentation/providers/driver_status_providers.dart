import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/driver_status_repository.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/utils/jwt_decoder.dart';

/// Driver status state
class DriverStatusState {
  final DriverProfile? profile;
  final bool isOnline;
  final bool isLoading;
  final bool isToggling;
  final String? error;
  final String? statusRestriction;

  DriverStatusState({
    this.profile,
    this.isOnline = false,
    this.isLoading = false,
    this.isToggling = false,
    this.error,
    this.statusRestriction,
  });

  DriverStatusState copyWith({
    DriverProfile? profile,
    bool? isOnline,
    bool? isLoading,
    bool? isToggling,
    String? error,
    String? statusRestriction,
  }) {
    return DriverStatusState(
      profile: profile ?? this.profile,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      isToggling: isToggling ?? this.isToggling,
      error: error,
      statusRestriction: statusRestriction,
    );
  }

  bool get canGoOnline => profile?.canGoOnline ?? false;
}

/// Driver status notifier
class DriverStatusNotifier extends StateNotifier<DriverStatusState> {
  final DriverStatusRepository _repository;
  final LocationService _locationService;
  final SocketService _socketService;

  DriverStatusNotifier({
    required DriverStatusRepository repository,
    required LocationService locationService,
    required SocketService socketService,
  })  : _repository = repository,
        _locationService = locationService,
        _socketService = socketService,
        super(DriverStatusState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadProfile();
  }

  /// Load driver profile
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final profile = await _repository.getDriverProfile();
      final isOnline = profile.status == DriverStatus.online;

      state = state.copyWith(
        profile: profile,
        isOnline: isOnline,
        isLoading: false,
        statusRestriction: profile.canGoOnline ? null : profile.statusRestrictionReason,
      );

      // Resume location broadcasting if was online
      if (isOnline && profile.canGoOnline) {
        await _startLocationBroadcasting();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle online/offline status
  Future<bool> toggleStatus() async {
    if (state.isToggling) return false;

    // Check eligibility before going online
    if (!state.isOnline) {
      final eligibility = await _repository.validateOnlineEligibility();
      if (eligibility['canGoOnline'] != true) {
        state = state.copyWith(
          statusRestriction: eligibility['reason'] as String?,
        );
        return false;
      }
    }

    state = state.copyWith(isToggling: true);

    try {
      final newStatus = state.isOnline ? DriverStatus.offline : DriverStatus.online;
      final success = await _repository.updateStatus(newStatus);

      if (success) {
        if (newStatus == DriverStatus.online) {
          await _startLocationBroadcasting();
        } else {
          _stopLocationBroadcasting();
        }

        state = state.copyWith(
          isOnline: newStatus == DriverStatus.online,
          isToggling: false,
          profile: state.profile?.copyWith(status: newStatus),
        );
        return true;
      } else {
        state = state.copyWith(
          isToggling: false,
          error: 'Failed to update status',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isToggling: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Go online
  Future<bool> goOnline() async {
    if (state.isOnline) return true;
    return await toggleStatus();
  }

  /// Go offline
  Future<bool> goOffline() async {
    if (!state.isOnline) return true;
    return await toggleStatus();
  }

  Future<void> _startLocationBroadcasting() async {
    try {
      // Connect socket first
      await _socketService.connect();

      // Start location broadcasting
      await _locationService.startBroadcasting();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start location services: $e',
      );
    }
  }

  void _stopLocationBroadcasting() {
    _locationService.stopBroadcasting();
    _socketService.emitDriverOffline();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear status restriction message
  void clearStatusRestriction() {
    state = state.copyWith(statusRestriction: null);
  }

  @override
  void dispose() {
    _stopLocationBroadcasting();
    super.dispose();
  }
}

// Providers
final driverStatusProvider =
    StateNotifierProvider<DriverStatusNotifier, DriverStatusState>((ref) {
  final repository = ref.watch(driverStatusRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  final socketService = ref.watch(socketServiceProvider);

  return DriverStatusNotifier(
    repository: repository,
    locationService: locationService,
    socketService: socketService,
  );
});

// Convenience providers
final isDriverOnlineProvider = Provider<bool>((ref) {
  return ref.watch(driverStatusProvider).isOnline;
});

final driverProfileProvider = Provider<DriverProfile?>((ref) {
  return ref.watch(driverStatusProvider).profile;
});
