import 'package:flutter/foundation.dart' show kIsWeb;

/// API Constants for Vectra apps
class ApiConstants {
  ApiConstants._();

  /// Base URL for the API
  /// For Web: use localhost since browser runs on same machine
  /// For Android device: use PC's IP address
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return 'http://10.12.89.212:3000'; // Your PC's IP for Android device
  }

  /// Auth endpoints
  static const String registerRider = '/auth/register/rider';
  static const String registerDriver = '/drivers/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String sessions = '/auth/sessions';
  static const String revokeAll = '/auth/revoke-all';
  static const String myPermissions = '/auth/me/permissions';

  /// OTP endpoints
  static const String generateOtp = '/auth/otp/generate';
  static const String verifyOtp = '/auth/otp/verify';

  /// Profile endpoints
  static const String profileMe = '/profile/me';
  static const String profilePrivacy = '/profile/privacy';
  static const String profileDeactivate = '/profile/deactivate';
  static const String profileDelete = '/profile/delete';
  static const String profileExport = '/profile/export';

  /// Availability endpoints (driver)
  static const String availabilityOnline = '/availability/online';
  static const String availabilityHeartbeat = '/availability/heartbeat';
  static const String availabilitySchedule = '/availability/schedule';
  static const String availabilityTimeoff = '/availability/timeoff';
  static const String availabilityIsAvailable = '/availability/is-available';

  /// Document endpoints (driver)
  static String driverDocumentsPresign(String driverProfileId) =>
      '/driver/documents/$driverProfileId/presign';
  static String driverDocumentsFinalize(String driverProfileId) =>
      '/driver/documents/$driverProfileId/finalize';
  static String driverDocumentsList(String driverProfileId) =>
      '/driver/documents/$driverProfileId';

  /// Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
