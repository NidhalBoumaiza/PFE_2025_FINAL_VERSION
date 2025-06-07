import 'package:equatable/equatable.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/doctor_entity.dart';

abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {}

class AllUsersLoading extends UsersState {}

class PatientsLoading extends UsersState {}

class DoctorsLoading extends UsersState {}

class UserStatisticsLoading extends UsersState {}

class AllUsersLoaded extends UsersState {
  final List<PatientEntity> patients;
  final List<DoctorEntity> doctors;

  const AllUsersLoaded({required this.patients, required this.doctors});

  @override
  List<Object?> get props => [patients, doctors];
}

class PatientsLoaded extends UsersState {
  final List<PatientEntity> patients;

  const PatientsLoaded(this.patients);

  @override
  List<Object?> get props => [patients];
}

class DoctorsLoaded extends UsersState {
  final List<DoctorEntity> doctors;

  const DoctorsLoaded(this.doctors);

  @override
  List<Object?> get props => [doctors];
}

class UserStatisticsLoaded extends UsersState {
  final Map<String, int> statistics;

  const UserStatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

class UsersError extends UsersState {
  final String message;

  const UsersError(this.message);

  @override
  List<Object?> get props => [message];
}

// CRUD States
class UserOperationLoading extends UsersState {}

class UserCreated extends UsersState {
  final String message;

  const UserCreated(this.message);

  @override
  List<Object?> get props => [message];
}

class UserUpdated extends UsersState {
  final String message;

  const UserUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class UserDeleted extends UsersState {
  final String message;

  const UserDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class UserOperationError extends UsersState {
  final String message;

  const UserOperationError(this.message);

  @override
  List<Object?> get props => [message];
}
