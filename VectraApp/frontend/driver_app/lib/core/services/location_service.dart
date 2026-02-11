import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../socket/socket_service.dart';
import '../api/api_client.dart';

/// Location service for background GPS broadcasting
class LocationService {
  final SocketService _socketService;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _broadcastTimer;
  Position? _lastPosition;
  bool _isBroadcasting = false;

  // Location update interval (5 seconds when moving, 10 when stationary)
  static const Duration _movingInterval = Duration(seconds: 5);
  static const Duration _stationaryInterval = Duration(seconds: 10);

  // Distance filter in meters (minimum movement to trigger update)
  static const double _distanceFilter = 10.0;

  LocationService({required SocketService socketService})
      : _socketService = socketService;

  bool get isBroadcasting => _isBroadcasting;
  Position? get lastPosition => _lastPosition;

  /// Check and request location permissions
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Request background location permission
  Future<bool> requestBackgroundPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse) {
      // Request always permission for background updates
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      return null;
    }
  }

  /// Start broadcasting location updates
  Future<void> startBroadcasting() async {
    if (_isBroadcasting) return;

    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    _isBroadcasting = true;

    // Start position stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        _lastPosition = position;
        _broadcastLocation(position);
      },
      onError: (error) {
        // Handle location errors
      },
    );

    // Also broadcast on timer for consistent updates
    _startBroadcastTimer();

    // Notify socket that driver is online
    _socketService.emitDriverOnline();
  }

  void _startBroadcastTimer() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(_movingInterval, (timer) {
      if (_lastPosition != null) {
        _broadcastLocation(_lastPosition!);
      }
    });
  }

  void _broadcastLocation(Position position) {
    if (!_isBroadcasting) return;

    _socketService.emitLocationUpdate(
      position.latitude,
      position.longitude,
    );
  }

  /// Stop broadcasting location updates
  void stopBroadcasting() {
    _isBroadcasting = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    // Notify socket that driver is offline
    _socketService.emitDriverOffline();
  }

  /// Calculate distance between two positions in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two positions
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Dispose resources
  void dispose() {
    stopBroadcasting();
  }
}

// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return LocationService(socketService: socketService);
});
