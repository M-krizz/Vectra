import 'package:flutter/foundation.dart';

/// API Endpoint constants for the Vectra Driver App
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - Configure based on environment
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1'; // iOS/Desktop
  }

  // Socket URL - Configure based on environment
  static String get wsUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000'; // iOS/Desktop
  }

  // Auth endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Driver endpoints
  static const String driverProfile = '/driver/profile';
  static const String driverStatus = '/driver/status';
  static const String driverDocuments = '/driver/documents';
  static const String driverLocation = '/driver/location';

  // Ride endpoints
  static const String rideAccept = '/rides/accept';
  static const String rideReject = '/rides/reject';
  static const String rideStart = '/rides/start';
  static const String rideComplete = '/rides/complete';
  static const String rideCancel = '/rides/cancel';
  static const String rideHistory = '/rides/history';
  static const String rideActive = '/rides/active';

  // Wallet endpoints
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String rateCard = '/wallet/rate-card';

  // Incentives endpoints
  static const String incentives = '/incentives';
  static const String incentiveProgress = '/incentives/progress';

  // Heatmap endpoints
  static const String heatmapDemand = '/heatmap/demand';
  static const String heatmapSurge = '/heatmap/surge';

  // Dynamic ride endpoints
  static String acceptRide(String rideId) => '/ride-requests/$rideId/accept';
  static String rejectRide(String rideId) => '/ride-requests/$rideId/reject';
  static String startTrip(String tripId) => '/trips/$tripId/start';
  static String completeTrip(String tripId) => '/trips/$tripId/complete';
  static String cancelTrip(String tripId) => '/trips/$tripId/cancel';
  static String updateTrip(String tripId) => '/rides/$tripId';
  static const String activeTrip = '/rides/active';
  static const String tripHistory = '/rides/history';
}
