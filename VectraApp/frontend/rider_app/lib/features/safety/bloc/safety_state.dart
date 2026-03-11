import 'package:equatable/equatable.dart';
import '../models/emergency_contact_model.dart';

abstract class SafetyState extends Equatable {
  const SafetyState();
  @override
  List<Object?> get props => [];
}

class SafetyInitial extends SafetyState {}

class SafetyContactsLoading extends SafetyState {}

class SafetyContactsLoaded extends SafetyState {
  final List<EmergencyContactModel> contacts;
  const SafetyContactsLoaded(this.contacts);
  @override
  List<Object?> get props => [contacts];
}

class SafetyError extends SafetyState {
  final String message;
  const SafetyError(this.message);
  @override
  List<Object?> get props => [message];
}
