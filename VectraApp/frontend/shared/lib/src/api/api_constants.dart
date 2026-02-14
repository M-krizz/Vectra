import 'package:flutter/foundation.dart';

/// API endpoint constants for the Vectra platform
class ApiConstants {
  ApiConstants._();

  // Base URL - Configure based on environment
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000'; // iOS/Desktop
  }

  // Auth endpoints
  static const String login = '/api/v1/auth/login';
  static const String registerRider = '/api/v1/auth/register';
  static const String logout = '/api/v1/auth/logout';
  static const String refreshToken = '/api/v1/auth/refresh';

  // Profile endpoints
  static const String profileMe = '/api/v1/profile/me';

  // Ride request endpoints
  static const String rideRequests = '/api/v1/ride-requests';
  static const String currentRideRequest = '/api/v1/ride-requests/current';
}
