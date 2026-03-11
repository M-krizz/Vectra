import 'package:equatable/equatable.dart';

abstract class SafetyEvent extends Equatable {
  const SafetyEvent();
  @override
  List<Object?> get props => [];
}

class LoadContactsRequested extends SafetyEvent {}

class AddContactRequested extends SafetyEvent {
  final String name;
  final String phoneNumber;
  final String? relationship;

  const AddContactRequested({
    required this.name,
    required this.phoneNumber,
    this.relationship,
  });
  @override
  List<Object?> get props => [name, phoneNumber, relationship];
}

class DeleteContactRequested extends SafetyEvent {
  final String id;
  const DeleteContactRequested(this.id);
  @override
  List<Object?> get props => [id];
}
