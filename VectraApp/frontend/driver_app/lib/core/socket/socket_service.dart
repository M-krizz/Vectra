import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../storage/secure_storage_service.dart';
import '../api/api_endpoints.dart';
import 'socket_events.dart';

/// Socket.IO service for real-time communication.
/// Auth is handled via handshake token — no separate authenticate event.
class SocketService {
  io.Socket? _socket;
  final SecureStorageService _storage;
  final Set<String> _joinedTripIds = <String>{};

  bool _isConnected = false;
  static const int _maxReconnectAttempts = 5;

  // Event controllers for broadcasting to listeners
  final StreamController<Map<String, dynamic>> _rideOfferController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _rideUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _tripStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _heatmapController =
      StreamController<Map<String, dynamic>>.broadcast();

  SocketService({required SecureStorageService storage}) : _storage = storage;

  // Public streams
  Stream<Map<String, dynamic>> get rideOfferStream => _rideOfferController.stream;
  Stream<Map<String, dynamic>> get rideUpdateStream => _rideUpdateController.stream;
  Stream<Map<String, dynamic>> get tripStatusStream => _tripStatusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get heatmapStream => _heatmapController.stream;

  bool get isConnected => _isConnected;

  /// Initialize and connect to the socket server.
  /// Backend authenticates via client.handshake.auth.token on connection.
  Future<void> connect() async {
    if (_socket != null) {
      if (_isConnected) return;
      // Reuse existing socket instance when reconnecting.
      _socket!.connect();
      return;
    }

    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    _socket = io.io(
      ApiEndpoints.baseUrl,
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
      _connectionController.add(true);
      for (final tripId in _joinedTripIds) {
        socket.emit(SocketEvents.joinTrip, {'tripId': tripId});
      }
    });

    socket.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
    });

    socket.onConnectError((error) {
      _isConnected = false;
      _connectionController.add(false);
    });

    // --- Server → Driver events ---

    // Ride offer from matching service
    socket.on(SocketEvents.rideOffered, (data) {
      if (data is Map) {
        _rideOfferController.add(Map<String, dynamic>.from(data));
      }
    });

    // Trip accepted confirmation
    socket.on(SocketEvents.driverAccepted, (data) {
      if (data is Map) {
        _rideUpdateController.add({
          'type': 'accepted',
          'data': Map<String, dynamic>.from(data),
        });
      }
    });

    // Trip rejected by another driver (re-offer)
    socket.on(SocketEvents.driverRejected, (data) {
      if (data is Map) {
        _rideUpdateController.add({
          'type': 'rejected',
          'data': Map<String, dynamic>.from(data),
        });
      }
    });

    // Trip status changed (state machine transition)
    socket.on(SocketEvents.tripStatusChanged, (data) {
      if (data is Map) {
        _tripStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    socket.on(SocketEvents.heatmapUpdate, (data) {
      if (data is Map) {
        _heatmapController.add({
          'type': 'demand',
          ...Map<String, dynamic>.from(data),
        });
      }
    });

    socket.on(SocketEvents.demandUpdate, (data) {
      if (data is Map) {
        _heatmapController.add({
          'type': 'demand',
          ...Map<String, dynamic>.from(data),
        });
      }
    });

    socket.on(SocketEvents.surgeUpdate, (data) {
      if (data is Map) {
        _heatmapController.add({
          'type': 'surge',
          ...Map<String, dynamic>.from(data),
        });
      }
    });

    // Error handling
    socket.on(SocketEvents.error, (error) {
      // Handle socket errors
    });
  }

  /// Emit driver location update.
  /// Backend expects: { lat, lng, heading?, speed? }
  void emitLocationUpdate(double lat, double lng,
      {double? heading, double? speed}) {
    if (!_isConnected) return;

    final payload = <String, dynamic>{
      'lat': lat,
      'lng': lng,
    };

    if (heading != null) {
      payload['heading'] = heading;
    }
    if (speed != null) {
      payload['speed'] = speed;
    }

    _socket?.emit(SocketEvents.updateLocation, payload);
  }

  /// Accept ride offer. Backend expects: { tripId }
  void acceptRide(String tripId) {
    if (!_isConnected) return;
    _socket?.emit(SocketEvents.rideAccept, {'tripId': tripId});
  }

  /// Reject ride offer. Backend expects: { tripId }
  void rejectRide(String tripId) {
    if (!_isConnected) return;
    _socket?.emit(SocketEvents.rideReject, {'tripId': tripId});
  }

  /// Join a trip room for GPS broadcasting
  void joinTrip(String tripId) {
    _joinedTripIds.add(tripId);
    if (!_isConnected) return;
    _socket?.emit(SocketEvents.joinTrip, {'tripId': tripId});
  }

  /// Leave a trip room
  void leaveTrip(String tripId) {
    _joinedTripIds.remove(tripId);
    if (!_isConnected) return;
    _socket?.emit(SocketEvents.leaveTrip, {'tripId': tripId});
  }

  /// Disconnect from socket server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _joinedTripIds.clear();
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _rideOfferController.close();
    _rideUpdateController.close();
    _tripStatusController.close();
    _connectionController.close();
    _heatmapController.close();
  }
}

// Provider for SocketService
final socketServiceProvider = Provider<SocketService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return SocketService(storage: storage);
});
