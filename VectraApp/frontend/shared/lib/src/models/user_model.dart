import 'package:equatable/equatable.dart';

/// User model matching backend User entity
class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final String role;
  final List<PreferredLocation> preferredLocations;
  final bool isVerified;
  final String? profileImageKey;
  final bool shareLocation;
  final bool shareRideHistory;
  final bool isActive;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.email,
    this.phone,
    required this.fullName,
    required this.role,
    this.preferredLocations = const [],
    this.isVerified = false,
    this.profileImageKey,
    this.shareLocation = true,
    this.shareRideHistory = true,
    this.isActive = true,
    this.isSuspended = false,
    this.suspensionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['fullName'] as String,
      role: json['role'] as String? ?? 'RIDER',
      preferredLocations:
          (json['preferredLocations'] as List<dynamic>?)
              ?.map(
                (e) => PreferredLocation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      isVerified: json['isVerified'] as bool? ?? false,
      profileImageKey: json['profileImageKey'] as String?,
      shareLocation: json['shareLocation'] as bool? ?? true,
      shareRideHistory: json['shareRideHistory'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      isSuspended: json['isSuspended'] as bool? ?? false,
      suspensionReason: json['suspensionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'role': role,
      'preferredLocations': preferredLocations.map((e) => e.toJson()).toList(),
      'isVerified': isVerified,
      'profileImageKey': profileImageKey,
      'shareLocation': shareLocation,
      'shareRideHistory': shareRideHistory,
      'isActive': isActive,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? role,
    List<PreferredLocation>? preferredLocations,
    bool? isVerified,
    String? profileImageKey,
    bool? shareLocation,
    bool? shareRideHistory,
    bool? isActive,
    bool? isSuspended,
    String? suspensionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      isVerified: isVerified ?? this.isVerified,
      profileImageKey: profileImageKey ?? this.profileImageKey,
      shareLocation: shareLocation ?? this.shareLocation,
      shareRideHistory: shareRideHistory ?? this.shareRideHistory,
      isActive: isActive ?? this.isActive,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    phone,
    fullName,
    role,
    preferredLocations,
    isVerified,
    profileImageKey,
    shareLocation,
    shareRideHistory,
    isActive,
    isSuspended,
    suspensionReason,
    createdAt,
    updatedAt,
  ];
}

/// Preferred location model
class PreferredLocation extends Equatable {
  final String name;
  final double lat;
  final double lng;

  const PreferredLocation({
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory PreferredLocation.fromJson(Map<String, dynamic> json) {
    return PreferredLocation(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'lat': lat, 'lng': lng};
  }

  @override
  List<Object?> get props => [name, lat, lng];
}
