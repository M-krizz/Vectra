import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/jwt_decoder.dart';

/// Driver verification status — matches backend DriverStatus enum.
class DriverVerificationStatus {
  static const String pendingVerification = 'PENDING_VERIFICATION';
  static const String documentsSubmitted = 'DOCUMENTS_SUBMITTED';
  static const String underReview = 'UNDER_REVIEW';
  static const String verified = 'VERIFIED';
  static const String suspended = 'SUSPENDED';
}

/// Driver profile model — matches backend DriverProfileEntity + nested User.
class DriverProfile {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final String? licenseNumber;
  final String? licenseState;
  final String verificationStatus; // DriverVerificationStatus
  final double rating;
  final int ratingCount;
  final double completionRate;
  final bool onlineStatus;
  final String? profileImage;
  final String? vehicleType;
  final int totalTrips;
  final bool documentsVerified;

  DriverProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.licenseNumber,
    this.licenseState,
    required this.verificationStatus,
    required this.rating,
    required this.ratingCount,
    required this.completionRate,
    required this.onlineStatus,
    this.profileImage,
    this.vehicleType,
    this.totalTrips = 0,
    this.documentsVerified = false,
  });

  /// Parse backend response which has shape:
  /// { id, userId, licenseNumber, licenseState, status, ratingAvg, ratingCount,
  ///   completionRate, onlineStatus, meta, user: { fullName, phone, email, profileImageKey } }
  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return DriverProfile(
      id: (json['id'] ?? '') as String,
      userId: (json['userId'] ?? json['user_id'] ?? '') as String,
      name: (user?['fullName'] ?? user?['full_name'] ?? json['name'] ?? '') as String,
      phone: (user?['phone'] ?? json['phone'] ?? '') as String,
      email: (user?['email'] ?? json['email']) as String?,
      licenseNumber: (json['licenseNumber'] ?? json['license_number']) as String?,
      licenseState: (json['licenseState'] ?? json['license_state']) as String?,
      verificationStatus: (json['status'] ?? DriverVerificationStatus.pendingVerification) as String,
      rating: (json['ratingAvg'] ?? json['rating_avg'] ?? 0) is num
          ? (json['ratingAvg'] ?? json['rating_avg'] ?? 0 as num).toDouble()
          : double.tryParse((json['ratingAvg'] ?? json['rating_avg'] ?? '0').toString()) ?? 0.0,
      ratingCount: (json['ratingCount'] ?? json['rating_count'] ?? 0) as int,
      completionRate: (json['completionRate'] ?? json['completion_rate'] ?? 0) is num
          ? (json['completionRate'] ?? json['completion_rate'] ?? 0 as num).toDouble()
          : double.tryParse((json['completionRate'] ?? json['completion_rate'] ?? '0').toString()) ?? 0.0,
      onlineStatus: (json['onlineStatus'] ?? json['online_status'] ?? false) as bool,
      profileImage: (user?['profileImageKey'] ?? user?['profile_image_key']) as String?,
      vehicleType: json['vehicleType'] as String?,
      totalTrips: (json['totalTrips'] ?? json['total_trips'] ?? 0) as int,
      documentsVerified: (json['documentsVerified'] ?? json['documents_verified'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'licenseNumber': licenseNumber,
      'status': verificationStatus,
      'ratingAvg': rating,
      'ratingCount': ratingCount,
      'completionRate': completionRate,
      'onlineStatus': onlineStatus,
    };
  }

  bool get isVerified => verificationStatus == DriverVerificationStatus.verified;
  bool get isSuspended => verificationStatus == DriverVerificationStatus.suspended;
  bool get canGoOnline => isVerified && !isSuspended;

  String get statusRestrictionReason {
    if (isSuspended) {
      return 'Your account is suspended. Please contact support.';
    }
    if (!isVerified) {
      return 'Your documents are pending verification.';
    }
    return '';
  }

  /// For DriverStatusNotifier compatibility: returns DriverStatus string.
  String get status => onlineStatus ? DriverStatus.online : DriverStatus.offline;

  DriverProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? licenseNumber,
    String? licenseState,
    String? verificationStatus,
    double? rating,
    int? ratingCount,
    double? completionRate,
    bool? onlineStatus,
    String? profileImage,
    String? vehicleType,
    String? status,
  }) {
    // If status is set (online/offline string), convert to onlineStatus bool
    bool? resolvedOnline = onlineStatus;
    if (status != null) {
      resolvedOnline = status == DriverStatus.online;
    }
    return DriverProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseState: licenseState ?? this.licenseState,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      completionRate: completionRate ?? this.completionRate,
      onlineStatus: resolvedOnline ?? this.onlineStatus,
      profileImage: profileImage ?? this.profileImage,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }
}

/// Repository for driver status operations — uses real backend APIs.
class DriverStatusRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  DriverStatusRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  /// Get driver profile from backend: GET /api/v1/drivers/profile
  Future<DriverProfile> getDriverProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.driverProfile);
      final data = response.data;
      final payload = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
          ? data['data'] as Map<String, dynamic>
          : (data is Map<String, dynamic> ? data : <String, dynamic>{});
      return DriverProfile.fromJson(payload);
    } catch (e) {
      throw Exception('Failed to fetch driver profile: $e');
    }
  }

  /// Toggle driver online status: POST /api/v1/drivers/online { online: bool }
  Future<bool> updateStatus(String status) async {
    try {
      final isOnline = status == DriverStatus.online;
      await _apiClient.post(
        ApiEndpoints.driverOnline,
        data: {'online': isOnline},
      );
      await _storage.saveDriverStatus(status);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if driver can go online
  Future<Map<String, dynamic>> validateOnlineEligibility() async {
    try {
      final profile = await getDriverProfile();

      if (profile.isSuspended) {
        return {
          'canGoOnline': false,
          'reason': 'Account suspended',
          'code': 'SUSPENDED',
        };
      }

      if (!profile.isVerified) {
        return {
          'canGoOnline': false,
          'reason': 'Documents pending verification',
          'code': 'DOCS_PENDING',
        };
      }

      return {'canGoOnline': true};
    } catch (e) {
      return {
        'canGoOnline': false,
        'reason': 'Unable to verify eligibility',
        'code': 'ERROR',
      };
    }
  }

  /// Get last saved status
  Future<String> getLastStatus() async {
    return await _storage.getDriverStatus() ?? DriverStatus.offline;
  }
}

// Provider
final driverStatusRepositoryProvider = Provider<DriverStatusRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return DriverStatusRepository(apiClient: apiClient, storage: storage);
});
