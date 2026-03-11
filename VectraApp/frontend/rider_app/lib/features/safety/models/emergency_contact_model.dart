class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? relationship;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      relationship: json['relationship'] as String?,
    );
  }
}
