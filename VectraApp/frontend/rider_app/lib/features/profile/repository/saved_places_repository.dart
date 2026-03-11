import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/saved_place_model.dart';

class SavedPlacesRepository {
  static const String _storageKey = 'saved_places_v1';

  static const List<SavedPlace> _defaultPlaces = [
    SavedPlace(
      id: '1',
      name: 'Home',
      address: 'RS Puram, Coimbatore',
      type: PlaceType.home,
    ),
    SavedPlace(
      id: '2',
      name: 'Work',
      address: 'Tidel Park, Coimbatore',
      type: PlaceType.work,
    ),
  ];

  final List<SavedPlace> _places = [
    ..._defaultPlaces,
  ];

  final _controller = StreamController<List<SavedPlace>>.broadcast();
  late final Future<void> _ready;

  Stream<List<SavedPlace>> get places => _controller.stream;

  SavedPlacesRepository() {
    _ready = _loadPlaces();
  }

  Future<List<SavedPlace>> getSavedPlaces() async {
    await _ready;
    return List.from(_places);
  }

  Future<void> addSavedPlace(SavedPlace place) async {
    await _ready;
    final newPlace = place.copyWith(id: const Uuid().v4());
    _places.add(newPlace);
    await _persistPlaces();
    _controller.add(List.from(_places));
  }

  Future<void> updateSavedPlace(SavedPlace place) async {
    await _ready;
    final index = _places.indexWhere((p) => p.id == place.id);
    if (index != -1) {
      _places[index] = place;
      await _persistPlaces();
      _controller.add(List.from(_places));
    }
  }

  Future<void> deleteSavedPlace(String id) async {
    await _ready;
    _places.removeWhere((p) => p.id == id);
    await _persistPlaces();
    _controller.add(List.from(_places));
  }

  Future<void> _loadPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);

      if (stored == null || stored.isEmpty) {
        _controller.add(List.from(_places));
        return;
      }

      final decoded = jsonDecode(stored);
      if (decoded is! List) {
        _controller.add(List.from(_places));
        return;
      }

      final loaded = decoded
          .whereType<Map<String, dynamic>>()
          .map(_savedPlaceFromJson)
          .toList();

      if (loaded.isNotEmpty) {
        _places
          ..clear()
          ..addAll(loaded);
      }
    } catch (_) {
      // Keep defaults if persistence is unavailable/corrupt.
    }

    _controller.add(List.from(_places));
  }

  Future<void> _persistPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_places.map(_savedPlaceToJson).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Map<String, dynamic> _savedPlaceToJson(SavedPlace place) {
    return {
      'id': place.id,
      'name': place.name,
      'address': place.address,
      'type': place.type.name,
      'latitude': place.latitude,
      'longitude': place.longitude,
    };
  }

  SavedPlace _savedPlaceFromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as String? ?? PlaceType.favorite.name;
    final type = PlaceType.values.firstWhere(
      (value) => value.name == typeValue,
      orElse: () => PlaceType.favorite,
    );

    return SavedPlace(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Saved Place',
      address: json['address'] as String? ?? '',
      type: type,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  void dispose() {
    _controller.close();
  }
}
