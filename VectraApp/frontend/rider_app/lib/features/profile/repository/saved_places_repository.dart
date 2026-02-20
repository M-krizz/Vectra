import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/saved_place_model.dart';

class SavedPlacesRepository {
  // Simulate local storage with a static list for now
  // In a real app, this would use SharedPreferences, Hive, or SQLite
  final List<SavedPlace> _places = [
    const SavedPlace(
      id: '1',
      name: 'Home',
      address: 'RS Puram, Coimbatore',
      type: PlaceType.home,
    ),
    const SavedPlace(
      id: '2',
      name: 'Work',
      address: 'Tidel Park, Coimbatore',
      type: PlaceType.work,
    ),
  ];

  final _controller = StreamController<List<SavedPlace>>.broadcast();

  Stream<List<SavedPlace>> get places => _controller.stream;

  SavedPlacesRepository() {
    _controller.add(List.from(_places));
  }

  Future<List<SavedPlace>> getSavedPlaces() async {
    // Simulate network/db delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_places);
  }

  Future<void> addSavedPlace(SavedPlace place) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newPlace = place.copyWith(id: const Uuid().v4());
    _places.add(newPlace);
    _controller.add(List.from(_places));
  }

  Future<void> updateSavedPlace(SavedPlace place) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _places.indexWhere((p) => p.id == place.id);
    if (index != -1) {
      _places[index] = place;
      _controller.add(List.from(_places));
    }
  }

  Future<void> deleteSavedPlace(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _places.removeWhere((p) => p.id == id);
    _controller.add(List.from(_places));
  }

  void dispose() {
    _controller.close();
  }
}
