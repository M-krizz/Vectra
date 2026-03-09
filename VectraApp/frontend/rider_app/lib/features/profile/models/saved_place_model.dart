import 'package:flutter/material.dart';

enum PlaceType { home, work, favorite }

class SavedPlace {
  final String id;
  final String name;
  final String address;
  final PlaceType type;
  final double? latitude;
  final double? longitude;

  const SavedPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    this.latitude,
    this.longitude,
  });

  SavedPlace copyWith({
    String? id,
    String? name,
    String? address,
    PlaceType? type,
    double? latitude,
    double? longitude,
  }) {
    return SavedPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
