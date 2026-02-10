/// Vehicle type for rate card
enum VehicleType {
  bike,
  auto,
  mini,
  sedan,
  suv,
}

/// Distance slab for pricing
class DistanceSlab {
  final double minDistance; // in km
  final double? maxDistance; // null means unlimited
  final double ratePerKm;

  DistanceSlab({
    required this.minDistance,
    this.maxDistance,
    required this.ratePerKm,
  });

  factory DistanceSlab.fromJson(Map<String, dynamic> json) {
    return DistanceSlab(
      minDistance: (json['minDistance'] as num).toDouble(),
      maxDistance: (json['maxDistance'] as num?)?.toDouble(),
      ratePerKm: (json['ratePerKm'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minDistance': minDistance,
      'maxDistance': maxDistance,
      'ratePerKm': ratePerKm,
    };
  }
}

/// Rate card model
class RateCard {
  final VehicleType vehicleType;
  final double baseFare;
  final List<DistanceSlab> distanceSlabs;
  final double nightFareMultiplier; // e.g., 1.5 for 50% increase
  final String nightStartTime; // e.g., "22:00"
  final String nightEndTime; // e.g., "06:00"
  final double? surgeMultiplier; // Current surge multiplier
  final double waitingChargePerMin;
  final double cancellationFee;

  RateCard({
    required this.vehicleType,
    required this.baseFare,
    required this.distanceSlabs,
    required this.nightFareMultiplier,
    required this.nightStartTime,
    required this.nightEndTime,
    this.surgeMultiplier,
    required this.waitingChargePerMin,
    required this.cancellationFee,
  });

  factory RateCard.fromJson(Map<String, dynamic> json) {
    return RateCard(
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == json['vehicleType'],
        orElse: () => VehicleType.mini,
      ),
      baseFare: (json['baseFare'] as num).toDouble(),
      distanceSlabs: (json['distanceSlabs'] as List)
          .map((slab) => DistanceSlab.fromJson(slab))
          .toList(),
      nightFareMultiplier: (json['nightFareMultiplier'] as num).toDouble(),
      nightStartTime: json['nightStartTime'] as String,
      nightEndTime: json['nightEndTime'] as String,
      surgeMultiplier: (json['surgeMultiplier'] as num?)?.toDouble(),
      waitingChargePerMin: (json['waitingChargePerMin'] as num).toDouble(),
      cancellationFee: (json['cancellationFee'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType.name,
      'baseFare': baseFare,
      'distanceSlabs': distanceSlabs.map((slab) => slab.toJson()).toList(),
      'nightFareMultiplier': nightFareMultiplier,
      'nightStartTime': nightStartTime,
      'nightEndTime': nightEndTime,
      'surgeMultiplier': surgeMultiplier,
      'waitingChargePerMin': waitingChargePerMin,
      'cancellationFee': cancellationFee,
    };
  }
}
