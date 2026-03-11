import 'package:bloc/bloc.dart';
import '../repository/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

export 'history_event.dart';
export 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository _repository;

  HistoryBloc({required HistoryRepository repository})
      : _repository = repository,
        super(HistoryInitial()) {
    on<LoadHistoryRequested>(_onLoadHistoryRequested);
  }

  Future<void> _onLoadHistoryRequested(
      LoadHistoryRequested event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final rides = await _repository.getRideHistory();
      emit(HistoryLoaded(rides));
    } catch (e) {
      emit(const HistoryError('Failed to load ride history.'));
    }
  }
}
