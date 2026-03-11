/// User model for the Vectra platform
class UserModel {
  final String id;
  final String? email;    // null when user signs in with phone only
  final String? fullName; // null until user completes their profile
  final String? phone;
  final String role;
  final String? profilePicture;
  final String? gender;

  const UserModel({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    required this.role,
    this.profilePicture,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      profilePicture: json['profilePicture'] as String?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'profilePicture': profilePicture,
      'gender': gender,
    };
  }

  /// True when this user still needs to set their display name
  bool get needsProfileCompletion => fullName == null || fullName!.isEmpty;

  @override
  String toString() => 'UserModel(id: $id, email: $email, fullName: $fullName, phone: $phone, role: $role)';
}

