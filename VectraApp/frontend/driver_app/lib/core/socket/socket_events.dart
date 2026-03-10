/// Socket.IO event constants for real-time communication.
/// All event names match the backend LocationGateway exactly.
class SocketEvents {
  SocketEvents._();

  // Connection events (built-in Socket.IO)
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';
  static const String reconnect = 'reconnect';
  static const String reconnectAttempt = 'reconnect_attempt';
  static const String reconnectError = 'reconnect_error';
  static const String reconnectFailed = 'reconnect_failed';

  // --- Driver → Server (emit) ---
  static const String updateLocation = 'update_location';
  static const String rideAccept = 'ride_accept';
  static const String rideReject = 'ride_reject';
  static const String joinTrip = 'join_trip';
  static const String leaveTrip = 'leave_trip';

  // --- Server → Driver (listen) ---
  static const String rideOffered = 'ride_offered';
  static const String driverAccepted = 'driver_accepted';
  static const String driverRejected = 'driver_rejected';
  static const String tripStatusChanged = 'trip_status_changed';
  static const String driverMoved = 'driver_moved';
  static const String heatmapUpdate = 'heatmap_update';
  static const String surgeUpdate = 'surge_update';
  static const String demandUpdate = 'demand_update';

  // Error events
  static const String error = 'error';
}
