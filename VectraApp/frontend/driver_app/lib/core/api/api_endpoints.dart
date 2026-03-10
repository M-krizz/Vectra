/// API Endpoint constants for the Vectra Driver App
/// All paths match the NestJS backend controllers exactly.
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - Configure based on environment
  static const String baseUrl = 'http://localhost:3000';

  // Auth endpoints (OTP ONLY) — AuthController: /api/v1/auth
  static const String requestOtp = '/api/v1/auth/request-otp';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String completeProfile = '/api/v1/auth/complete-profile';

  // Driver endpoints — DriversController: /api/v1/drivers
  static const String driverProfile = '/api/v1/drivers/profile';
  static const String driverOnline = '/api/v1/drivers/online';
  static const String driverDocumentsUpload = '/api/v1/drivers/documents/upload';
  static const String driverVehicles = '/api/v1/drivers/vehicles';

  // Trip endpoints — TripsController: /api/v1/trips
  static const String trips = '/api/v1/trips';
  static String tripById(String tripId) => '/api/v1/trips/$tripId';
  static String tripStatus(String tripId) => '/api/v1/trips/$tripId/status';
  static String tripLocation(String tripId) => '/api/v1/trips/$tripId/location';
  static String tripFare(String tripId) => '/api/v1/trips/$tripId/fare';
  static String tripOtpGenerate(String tripId) => '/api/v1/trips/$tripId/otp/generate';
  static String tripOtpVerify(String tripId) => '/api/v1/trips/$tripId/otp/verify';

  // Fare endpoints — FareController: /api/v1/fare
  static const String fareRateCards = '/api/v1/fare/rate-cards';

  // Wallet/Payments endpoints — PaymentsController: /api/v1/payments
  static const String wallet = '/api/v1/payments/wallet';
  static const String walletBalance = '/api/v1/payments/wallet';
  static const String walletTopup = '/api/v1/payments/wallet/topup';
  static const String walletWithdraw = '/api/v1/payments/wallet/withdraw';
  static const String walletTransactions = '/api/v1/payments/wallet/transactions';

  // Trip history
  static const String tripHistory = '/api/v1/trips';

  // Safety endpoints — SafetyController: /api/v1/safety
  static const String safetyIncidents = '/api/v1/safety/incidents';
  static const String safetySos = '/api/v1/safety/sos';
  static const String safetyContacts = '/api/v1/safety/contacts';

  // Incentives endpoints — IncentivesController: /api/v1/incentives
  static const String incentives = '/api/v1/incentives';
  static const String incentivesActive = '/api/v1/incentives/active';
  static const String incentivesCompleted = '/api/v1/incentives/completed';
}
