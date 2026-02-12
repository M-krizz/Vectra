/// Socket.IO event constants for real-time communication
class SocketEvents {
  SocketEvents._();

  // Connection events
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';
  static const String reconnect = 'reconnect';
  static const String reconnectAttempt = 'reconnect_attempt';
  static const String reconnectError = 'reconnect_error';
  static const String reconnectFailed = 'reconnect_failed';

  // Authentication events
  static const String authenticate = 'authenticate';
  static const String authenticated = 'authenticated';
  static const String authError = 'auth_error';

  // Driver status events
  static const String driverOnline = 'driver:online';
  static const String driverOffline = 'driver:offline';
  static const String driverLocationUpdate = 'driver:location_update';

  // Ride events
  static const String rideOffer = 'ride:offer';
  static const String rideOfferExpired = 'ride:offer_expired';
  static const String rideAccepted = 'ride:accepted';
  static const String rideRejected = 'ride:rejected';
  static const String rideCancelled = 'ride:cancelled';
  static const String rideStarted = 'ride:started';
  static const String rideCompleted = 'ride:completed';
  static const String riderLocationUpdate = 'ride:rider_location';

  // Navigation events
  static const String routeUpdate = 'navigation:route_update';
  static const String etaUpdate = 'navigation:eta_update';

  // Heatmap events
  static const String heatmapUpdate = 'heatmap:update';
  static const String surgeUpdate = 'heatmap:surge_update';

  // Notification events
  static const String notification = 'notification';
  static const String alert = 'alert';

  // Error events
  static const String error = 'error';
}
