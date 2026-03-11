import 'package:equatable/equatable.dart';
import '../models/ride_history_model.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<RideHistoryModel> rides;
  const HistoryLoaded(this.rides);
  @override
  List<Object?> get props => [rides];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
