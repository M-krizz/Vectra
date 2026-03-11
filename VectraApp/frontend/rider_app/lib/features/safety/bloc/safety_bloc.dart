import 'package:bloc/bloc.dart';
import '../repository/safety_repository.dart';
import 'safety_event.dart';
import 'safety_state.dart';

export 'safety_event.dart';
export 'safety_state.dart';

class SafetyBloc extends Bloc<SafetyEvent, SafetyState> {
  final SafetyRepository _repository;

  SafetyBloc({required SafetyRepository repository})
      : _repository = repository,
        super(SafetyInitial()) {
    on<LoadContactsRequested>(_onLoadContactsRequested);
    on<AddContactRequested>(_onAddContactRequested);
    on<DeleteContactRequested>(_onDeleteContactRequested);
  }

  Future<void> _onLoadContactsRequested(
      LoadContactsRequested event, Emitter<SafetyState> emit) async {
    emit(SafetyContactsLoading());
    try {
      final contacts = await _repository.getContacts();
      emit(SafetyContactsLoaded(contacts));
    } catch (e) {
      emit(const SafetyError('Failed to load contacts'));
    }
  }

  Future<void> _onAddContactRequested(
      AddContactRequested event, Emitter<SafetyState> emit) async {
    try {
      await _repository.addContact(
        name: event.name,
        phoneNumber: event.phoneNumber,
        relationship: event.relationship,
      );
      add(LoadContactsRequested());
    } catch (e) {
      final currentState = state;
      if (currentState is SafetyContactsLoaded) {
        // Keep current state but notify error optionally via effect
      } else {
        emit(const SafetyError('Failed to add contact'));
      }
    }
  }

  Future<void> _onDeleteContactRequested(
      DeleteContactRequested event, Emitter<SafetyState> emit) async {
    try {
      await _repository.deleteContact(event.id);
      add(LoadContactsRequested());
    } catch (e) {
      // Ignore/handle error gracefully
    }
  }
}
