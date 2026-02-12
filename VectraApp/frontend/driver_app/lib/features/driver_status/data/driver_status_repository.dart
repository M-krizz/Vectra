import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/jwt_decoder.dart';

/// Driver profile and status model
class DriverProfile {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String status;
  final double rating;
  final int totalTrips;
  final bool isSuspended;
  final bool documentsVerified;
  final String? profileImage;
  final String? vehicleType;

  DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.status,
    required this.rating,
    required this.totalTrips,
    required this.isSuspended,
    required this.documentsVerified,
    this.profileImage,
    this.vehicleType,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      status: json['status'] as String? ?? DriverStatus.offline,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalTrips: json['total_trips'] as int? ?? 0,
      isSuspended: json['is_suspended'] as bool? ?? false,
      documentsVerified: json['documents_verified'] as bool? ?? false,
      profileImage: json['profile_image'] as String?,
      vehicleType: json['vehicle_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'status': status,
      'rating': rating,
      'total_trips': totalTrips,
      'is_suspended': isSuspended,
      'documents_verified': documentsVerified,
      'profile_image': profileImage,
      'vehicle_type': vehicleType,
    };
  }

  bool get canGoOnline => !isSuspended && documentsVerified;

  String get statusRestrictionReason {
    if (isSuspended) {
      return 'Your account is suspended. Please contact support.';
    }
    if (!documentsVerified) {
      return 'Your documents are pending verification.';
    }
    return '';
  }

  DriverProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? status,
    double? rating,
    int? totalTrips,
    bool? isSuspended,
    bool? documentsVerified,
    String? profileImage,
    String? vehicleType,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      isSuspended: isSuspended ?? this.isSuspended,
      documentsVerified: documentsVerified ?? this.documentsVerified,
      profileImage: profileImage ?? this.profileImage,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }
}

/// Repository for driver status operations
class DriverStatusRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  DriverStatusRepository({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  /// Get driver profile and status
  Future<DriverProfile> getDriverProfile() async {
    try {
      // In production, fetch from API
      // final response = await _apiClient.get(ApiEndpoints.driverProfile);
      // return DriverProfile.fromJson(response.data);

      // Mock profile for development
      await Future.delayed(const Duration(milliseconds: 500));

      return DriverProfile(
        id: 'driver_123',
        name: 'John Driver',
        phone: '+919876543210',
        email: 'john@example.com',
        status: await _storage.getDriverStatus() ?? DriverStatus.offline,
        rating: 4.8,
        totalTrips: 342,
        isSuspended: false,
        documentsVerified: true,
        vehicleType: 'Bike',
      );
    } catch (e) {
      throw Exception('Failed to fetch driver profile');
    }
  }

  /// Update driver status (online/offline)
  Future<bool> updateStatus(String status) async {
    try {
      // In production, call API
      // await _apiClient.put(
      //   ApiEndpoints.driverStatus,
      //   data: {'status': status},
      // );

      await Future.delayed(const Duration(milliseconds: 300));
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

      if (!profile.documentsVerified) {
        return {
          'canGoOnline': false,
          'reason': 'Documents pending verification',
          'code': 'DOCS_PENDING',
        };
      }

      // Check wallet balance
      // In production, fetch actual balance
      final walletBalance = 500.0; // Mock balance
      final minimumBalance = 100.0;

      if (walletBalance < minimumBalance) {
        return {
          'canGoOnline': false,
          'reason': 'Low wallet balance. Minimum ₹$minimumBalance required.',
          'code': 'LOW_BALANCE',
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
