import 'package:equatable/equatable.dart';
import '../models/saved_place_model.dart';

abstract class SavedPlacesEvent extends Equatable {
  const SavedPlacesEvent();

  @override
  List<Object> get props => [];
}

class LoadSavedPlaces extends SavedPlacesEvent {}

class AddSavedPlace extends SavedPlacesEvent {
  final SavedPlace place;

  const AddSavedPlace(this.place);

  @override
  List<Object> get props => [place];
}

class UpdateSavedPlace extends SavedPlacesEvent {
  final SavedPlace place;

  const UpdateSavedPlace(this.place);

  @override
  List<Object> get props => [place];
}

class DeleteSavedPlace extends SavedPlacesEvent {
  final String id;

  const DeleteSavedPlace(this.id);

  @override
  List<Object> get props => [id];
}
