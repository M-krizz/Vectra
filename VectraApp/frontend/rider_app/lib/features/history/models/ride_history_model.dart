/// Model for ride history
class RideHistoryModel {
  final String id;
  final String pickupAddress;
  final String destinationAddress;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final String vehicleType;
  final double fare;
  final String status; // completed, cancelled
  final DateTime rideDate;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final double? rating;
  final String? review;
  final double distance;
  final int durationMinutes;
  final String paymentMethod;

  const RideHistoryModel({
    required this.id,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.vehicleType,
    required this.fare,
    required this.status,
    required this.rideDate,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleNumber,
    this.rating,
    this.review,
    required this.distance,
    required this.durationMinutes,
    required this.paymentMethod,
  });

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) {
    return RideHistoryModel(
      id: json['id'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      pickupLat: (json['pickupLat'] ?? 0).toDouble(),
      pickupLng: (json['pickupLng'] ?? 0).toDouble(),
      destinationLat: (json['destinationLat'] ?? 0).toDouble(),
      destinationLng: (json['destinationLng'] ?? 0).toDouble(),
      vehicleType: json['vehicleType'] ?? 'sedan',
      fare: (json['fare'] ?? 0).toDouble(),
      status: json['status'] ?? 'completed',
      rideDate: json['rideDate'] != null
          ? DateTime.parse(json['rideDate'])
          : DateTime.now(),
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      rating: json['rating']?.toDouble(),
      review: json['review'],
      distance: (json['distance'] ?? 0).toDouble(),
      durationMinutes: json['durationMinutes'] ?? 0,
      paymentMethod: json['paymentMethod'] ?? 'cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'vehicleType': vehicleType,
      'fare': fare,
      'status': status,
      'rideDate': rideDate.toIso8601String(),
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'rating': rating,
      'review': review,
      'distance': distance,
      'durationMinutes': durationMinutes,
      'paymentMethod': paymentMethod,
    };
  }
}
