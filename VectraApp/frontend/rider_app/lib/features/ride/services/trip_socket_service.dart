import 'dart:async';
import 'dart:math';
import 'package:socket_io_client/socket_io_client.dart' as io;

// ─── Typed event models ────────────────────────────────────────────────────

class TripStatusEvent {
  final String tripId;
  final String status; // REQUESTED|ASSIGNED|ARRIVING|IN_PROGRESS|COMPLETED|CANCELLED
  final Map<String, dynamic> payload;
  const TripStatusEvent({
    required this.tripId,
    required this.status,
    this.payload = const {},
  });
}

class LocationUpdateEvent {
  final String tripId;
  final double lat;
  final double lng;
  final int? etaSeconds;
  const LocationUpdateEvent({
    required this.tripId,
    required this.lat,
    required this.lng,
    this.etaSeconds,
  });
}

class TripNotificationEvent {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  const TripNotificationEvent({
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
  });
}

// ─── Service ──────────────────────────────────────────────────────────────

/// Manages the WebSocket connection for real-time trip updates.
///
/// Usage:
///   final svc = TripSocketService(baseUrl: '...');
///   svc.connect(token: accessToken);
///   svc.tripStatusStream.listen((e) => rideBloc.add(...));
///   svc.joinTripRoom(tripId);
class TripSocketService {
  final String baseUrl;

  TripSocketService({required this.baseUrl});

  io.Socket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;
  String? _currentToken;
  String? _currentTripId;

  bool get isConnected => _socket?.connected ?? false;

  // Stream controllers — broadcast so multiple listeners are OK
  final _statusController =
      StreamController<TripStatusEvent>.broadcast();
  final _locationController =
      StreamController<LocationUpdateEvent>.broadcast();
  final _notificationController =
      StreamController<TripNotificationEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _otpController = StreamController<Map<String, dynamic>>.broadcast();
  final _poolTimeoutController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<TripStatusEvent> get tripStatusStream => _statusController.stream;
  Stream<LocationUpdateEvent> get locationStream => _locationController.stream;
  Stream<TripNotificationEvent> get notificationStream =>
      _notificationController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get otpStream => _otpController.stream;
  /// Emits when the server signals a pool search has timed out with no match.
  Stream<Map<String, dynamic>> get poolTimeoutStream =>
      _poolTimeoutController.stream;
  void connect({required String token}) {
    if (_socket?.connected == true && _currentToken == token) return;
    _currentToken = token;
    _intentionalDisconnect = false;
    _initSocket(token);
  }

  /// Subscribe to a specific trip's room.
  void joinTripRoom(String tripId) {
    _currentTripId = tripId;
    _socket?.emit('join_trip', {'tripId': tripId});
  }

  /// Leave a trip room.
  void leaveTripRoom(String tripId) {
    _socket?.emit('leave_trip', {'tripId': tripId});
    if (_currentTripId == tripId) _currentTripId = null;
  }

  /// Graceful disconnect (no reconnect).
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _reconnectAttempts = 0;
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _locationController.close();
    _notificationController.close();
    _connectionController.close();
    _otpController.close();
    _poolTimeoutController.close();
  }

  // ── Socket initialisation ──────────────────────────────────────────────

  void _initSocket(String token) {
    _socket?.dispose();

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        _connectionController.add(true);

        // Re-join trip room if we had one
        if (_currentTripId != null) {
          joinTripRoom(_currentTripId!);
        }
      })
      ..onDisconnect((_) {
        _connectionController.add(false);
        if (!_intentionalDisconnect) _scheduleReconnect();
      })
      ..onConnectError((_) {
        _connectionController.add(false);
        if (!_intentionalDisconnect) _scheduleReconnect();
      })
      // ── Trip events ────────────────────────────────────────────────────
      ..on('trip_status_changed', (data) {
        if (data is Map) {
          _statusController.add(TripStatusEvent(
            tripId: data['tripId']?.toString() ?? '',
            status: data['newStatus']?.toString() ?? '',
            payload: Map<String, dynamic>.from(data),
          ));
        }
      })
      ..on('driver_moved', (data) {
        if (data is Map) {
          _locationController.add(LocationUpdateEvent(
            tripId: _currentTripId ?? '',
            lat: (data['lat'] as num?)?.toDouble() ?? 0,
            lng: (data['lng'] as num?)?.toDouble() ?? 0,
            etaSeconds: data['etaSeconds'] as int?,
          ));
        }
      })
      ..on('notification', (data) {
        if (data is Map) {
          _notificationController.add(TripNotificationEvent(
            type: data['type']?.toString() ?? '',
            title: data['title']?.toString() ?? '',
            body: data['body']?.toString() ?? '',
            data: data['data'] is Map
                ? Map<String, dynamic>.from(data['data'] as Map)
                : {},
          ));
        }
      })
      // ── OTP events (sent directly to rider) ────────────────────────────
      ..on('trip_otp', (data) {
        if (data is Map) {
          _otpController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('otp_verified', (data) {
        if (data is Map) {
          _statusController.add(TripStatusEvent(
            tripId: data['tripId']?.toString() ?? '',
            status: 'OTP_VERIFIED',
            payload: Map<String, dynamic>.from(data),
          ));
        }
      })
      // ── Session events ─────────────────────────────────────────────────
      ..on('token_expired', (_) {
        _notificationController.add(const TripNotificationEvent(
          type: 'session_expired',
          title: 'Session Expired',
          body: 'Please log in again.',
        ));      })
      // ── Trip created (SOLO): auto-join room so status events reach the rider ─
      ..on('trip_created', (data) {
        if (data is Map) {
          final tripId = data['tripId']?.toString();
          if (tripId != null && tripId.isNotEmpty) {
            joinTripRoom(tripId);
          }
        }
      })
      // ── Pool timeout: no match found within window ─────────────────────────
      ..on('pool_timeout', (data) {
        if (data is Map) {
          _poolTimeoutController.add(Map<String, dynamic>.from(data));
          // Also surface as a notification so any generic listener is aware
          _notificationController.add(TripNotificationEvent(
            type: 'pool_timeout',
            title: 'No Pool Found',
            body: data['message']?.toString() ??
                'No pool match found. Please try again.',
            data: Map<String, dynamic>.from(data),
          ));
        }      });

    _socket!.connect();
  }

  // ── Reconnect with exponential backoff ─────────────────────────────────

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    const maxAttempts = 8;
    if (_reconnectAttempts >= maxAttempts) return;

    final delaySeconds = min(2 * pow(2, _reconnectAttempts).toInt(), 60);
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_intentionalDisconnect && _currentToken != null) {
        _initSocket(_currentToken!);
      }
    });
  }
}
