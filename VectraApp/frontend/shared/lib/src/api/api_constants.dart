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

  // Auth endpoints (OTP-only, no password)
  static const String requestOtp = '/api/v1/auth/request-otp';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String completeProfile = '/api/v1/auth/complete-profile';
  static const String logout = '/api/v1/auth/logout';
  static const String logoutAll = '/api/v1/auth/logout-all';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String me = '/api/v1/auth/me';

  // Profile endpoints
  static const String profileMe = '/api/v1/profile/me';

  // Ride request endpoints
  static const String rideRequests = '/api/v1/ride-requests';
  static const String currentRideRequest = '/api/v1/ride-requests/current';

  // Trip endpoints
  static const String trips = '/api/v1/trips';
  static String tripById(String id) => '/api/v1/trips/$id';
  static String tripStatus(String id) => '/api/v1/trips/$id/status';
  static String tripOtpGenerate(String id) => '/api/v1/trips/$id/otp/generate';
  static String tripOtpVerify(String id) => '/api/v1/trips/$id/otp/verify';
  static String tripFare(String id) => '/api/v1/trips/$id/fare';
  static String tripRating(String id) => '/api/v1/trips/$id/rating';

  // Fare estimation
  static const String fareEstimate = '/api/v1/fare/estimate';

  // Cancellations
  static const String cancelByRider = '/api/v1/cancellations/rider';

  // Maps
  static const String placesAutocomplete = '/api/v1/maps/places/autocomplete';
  static const String placesDetails = '/api/v1/maps/places/details';
  static const String directions = '/api/v1/maps/directions';

  // Safety
  static const String safetyContacts = '/api/v1/safety/contacts';

  // Payments / Wallet
  static const String wallet = '/api/v1/payments/wallet';
  static const String walletTopup = '/api/v1/payments/wallet/topup';

  // Pooling
  static const String poolingCandidates = '/api/v1/pooling/candidates';
  static const String poolingFinalize = '/api/v1/pooling/finalize';
}

