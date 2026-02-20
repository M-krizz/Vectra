import 'package:flutter_bloc/flutter_bloc.dart';
import 'saved_places_event.dart';
import 'saved_places_state.dart';
import '../repository/saved_places_repository.dart';

class SavedPlacesBloc extends Bloc<SavedPlacesEvent, SavedPlacesState> {
  final SavedPlacesRepository _repository;

  SavedPlacesBloc({required SavedPlacesRepository repository})
      : _repository = repository,
        super(SavedPlacesInitial()) {
    on<LoadSavedPlaces>(_onLoadSavedPlaces);
    on<AddSavedPlace>(_onAddSavedPlace);
    on<UpdateSavedPlace>(_onUpdateSavedPlace);
    on<DeleteSavedPlace>(_onDeleteSavedPlace);
  }

  Future<void> _onLoadSavedPlaces(
    LoadSavedPlaces event,
    Emitter<SavedPlacesState> emit,
  ) async {
    emit(SavedPlacesLoading());
    try {
      final places = await _repository.getSavedPlaces();
      emit(SavedPlacesLoaded(places));
    } catch (e) {
      emit(SavedPlacesError("Failed to load saved places: ${e.toString()}"));
    }
  }

  Future<void> _onAddSavedPlace(
    AddSavedPlace event,
    Emitter<SavedPlacesState> emit,
  ) async {
    // Optimistic update or reload?
    // Let's do reload for simplicity and consistency
    try {
      await _repository.addSavedPlace(event.place);
      add(LoadSavedPlaces());
    } catch (e) {
      emit(SavedPlacesError("Failed to add place: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateSavedPlace(
    UpdateSavedPlace event,
    Emitter<SavedPlacesState> emit,
  ) async {
    try {
      await _repository.updateSavedPlace(event.place);
      add(LoadSavedPlaces());
    } catch (e) {
      emit(SavedPlacesError("Failed to update place: ${e.toString()}"));
    }
  }

  Future<void> _onDeleteSavedPlace(
    DeleteSavedPlace event,
    Emitter<SavedPlacesState> emit,
  ) async {
    try {
      await _repository.deleteSavedPlace(event.id);
      add(LoadSavedPlaces());
    } catch (e) {
      emit(SavedPlacesError("Failed to delete place: ${e.toString()}"));
    }
  }
}
