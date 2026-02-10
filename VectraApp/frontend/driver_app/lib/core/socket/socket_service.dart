import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../storage/secure_storage_service.dart';
import '../api/api_client.dart';
import 'socket_events.dart';

/// Socket.IO service for real-time communication
class SocketService {
  io.Socket? _socket;
  final SecureStorageService _storage;

  bool _isConnected = false;
  bool _isAuthenticated = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Event controllers for broadcasting to listeners
  final StreamController<Map<String, dynamic>> _rideOfferController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _rideUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _heatmapController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  SocketService({required SecureStorageService storage}) : _storage = storage;

  // Public streams
  Stream<Map<String, dynamic>> get rideOfferStream => _rideOfferController.stream;
  Stream<Map<String, dynamic>> get rideUpdateStream => _rideUpdateController.stream;
  Stream<Map<String, dynamic>> get heatmapStream => _heatmapController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;

  /// Initialize and connect to the socket server
  Future<void> connect() async {
    if (_isSimulationMode) {
      startSimulation();
      return;
    }

    if (_socket != null && _isConnected) return;

    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    _socket = io.io(
      'wss://api.vectra.com',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': accessToken})
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _setupEventHandlers();
    _socket!.connect();
  }

  void _setupEventHandlers() {
    final socket = _socket!;

    // Connection events
    socket.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      _authenticate();
    });

    socket.onDisconnect((_) {
      _isConnected = false;
      _isAuthenticated = false;
      _connectionController.add(false);
    });

    socket.onConnectError((error) {
      _isConnected = false;
      _connectionController.add(false);
    });

    socket.onReconnect((_) {
      _reconnectAttempts = 0;
      _authenticate();
    });

    socket.onReconnectAttempt((attempt) {
      _reconnectAttempts = attempt as int;
    });

    // Auth events
    socket.on(SocketEvents.authenticated, (data) {
      _isAuthenticated = true;
    });

    socket.on(SocketEvents.authError, (error) {
      _isAuthenticated = false;
      disconnect();
    });

    // Ride events
    socket.on(SocketEvents.rideOffer, (data) {
      _rideOfferController.add(Map<String, dynamic>.from(data));
    });

    socket.on(SocketEvents.rideOfferExpired, (data) {
      _rideUpdateController.add({
        'type': 'expired',
        'data': Map<String, dynamic>.from(data),
      });
    });

    socket.on(SocketEvents.rideAccepted, (data) {
      _rideUpdateController.add({
        'type': 'accepted',
        'data': Map<String, dynamic>.from(data),
      });
    });

    socket.on(SocketEvents.rideCancelled, (data) {
      _rideUpdateController.add({
        'type': 'cancelled',
        'data': Map<String, dynamic>.from(data),
      });
    });

    socket.on(SocketEvents.rideCompleted, (data) {
      _rideUpdateController.add({
        'type': 'completed',
        'data': Map<String, dynamic>.from(data),
      });
    });

    // Heatmap events
    socket.on(SocketEvents.heatmapUpdate, (data) {
      _heatmapController.add(Map<String, dynamic>.from(data));
    });

    socket.on(SocketEvents.surgeUpdate, (data) {
      _heatmapController.add({
        'type': 'surge',
        'data': Map<String, dynamic>.from(data),
      });
    });

    // Error handling
    socket.on(SocketEvents.error, (error) {
      // Handle socket errors
    });
  }

  // --- Mock Simulation Logic ---

  Timer? _simulationTimer;
  bool _isSimulationMode = true; // Force simulation for now

  void startSimulation() {
    if (!_isSimulationMode) return;
    
    _isConnected = true;
    _isAuthenticated = true;
    _connectionController.add(true);

    // Simulate incoming ride request after 5 seconds
    _simulationTimer?.cancel();
    _simulationTimer = Timer(const Duration(seconds: 5), () {
      _simulateRideOffer();
    });
  }

  void _simulateRideOffer() {
    final mockRide = {
      'id': 'ride_${DateTime.now().millisecondsSinceEpoch}',
      'riderId': 'rider_001',
      'riderName': 'Alice Wonderland',
      'riderPhone': '+919876543210',
      'riderRating': 4.8,
      'pickupLocation': {'lat': 12.9716, 'lng': 77.5946}, // Bangalore
      'pickupAddress': 'MG Road Metro Station, Bangalore',
      'dropoffLocation': {'lat': 12.9352, 'lng': 77.6245}, // Koramangala
      'dropoffAddress': 'Forum Mall, Koramangala',
      'estimatedFare': 250.0,
      'estimatedDistance': 5.2,
      'estimatedDuration': 25,
      'vehicleType': 'Sedan',
      'requestedAt': DateTime.now().toIso8601String(),
      'specialInstructions': 'Waiting near the entrance',
    };

    _rideOfferController.add(mockRide);
  }
  
  void stopSimulation() {
    _simulationTimer?.cancel();
  }

  Future<void> _authenticate() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken != null) {
      _socket?.emit(SocketEvents.authenticate, {'token': accessToken});
    }
  }

  /// Emit driver location update
  void emitLocationUpdate(double latitude, double longitude) {
    if (!_isConnected || !_isAuthenticated) return;

    _socket?.emit(SocketEvents.driverLocationUpdate, {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Emit driver online status
  void emitDriverOnline() {
    if (!_isConnected || !_isAuthenticated) return;
    _socket?.emit(SocketEvents.driverOnline);
  }

  /// Emit driver offline status
  void emitDriverOffline() {
    if (!_isConnected || !_isAuthenticated) return;
    _socket?.emit(SocketEvents.driverOffline);
  }

  /// Accept ride offer
  void acceptRide(String rideId) {
    if (!_isConnected || !_isAuthenticated) return;
    _socket?.emit(SocketEvents.rideAccepted, {'ride_id': rideId});
  }

  /// Reject ride offer
  void rejectRide(String rideId, {String? reason}) {
    if (!_isConnected || !_isAuthenticated) return;
    _socket?.emit(SocketEvents.rideRejected, {
      'ride_id': rideId,
      'reason': reason,
    });
  }

  /// Disconnect from socket server
  void disconnect() {
    stopSimulation();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isAuthenticated = false;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _rideOfferController.close();
    _rideUpdateController.close();
    _heatmapController.close();
    _connectionController.close();
  }
}

// Provider for SocketService
final socketServiceProvider = Provider<SocketService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return SocketService(storage: storage);
});
