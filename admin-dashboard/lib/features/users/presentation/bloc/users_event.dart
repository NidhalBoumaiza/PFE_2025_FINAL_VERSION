import 'package:equatable/equatable.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/doctor_entity.dart';

abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllUsers extends UsersEvent {}

class LoadPatients extends UsersEvent {}

class LoadDoctors extends UsersEvent {}

class LoadUserStatistics extends UsersEvent {}

class RefreshAllUsers extends UsersEvent {}

class StartListeningToUsers extends UsersEvent {}

class StopListeningToUsers extends UsersEvent {}

// CRUD Events
class CreatePatientEvent extends UsersEvent {
  final PatientEntity patient;
  final String password;

  const CreatePatientEvent({required this.patient, required this.password});

  @override
  List<Object?> get props => [patient, password];
}

class CreateDoctorEvent extends UsersEvent {
  final DoctorEntity doctor;
  final String password;

  const CreateDoctorEvent({required this.doctor, required this.password});

  @override
  List<Object?> get props => [doctor, password];
}

class UpdatePatientEvent extends UsersEvent {
  final PatientEntity patient;

  const UpdatePatientEvent({required this.patient});

  @override
  List<Object?> get props => [patient];
}

class UpdateDoctorEvent extends UsersEvent {
  final DoctorEntity doctor;

  const UpdateDoctorEvent({required this.doctor});

  @override
  List<Object?> get props => [doctor];
}

class DeleteUserEvent extends UsersEvent {
  final String userId;
  final String userType;

  const DeleteUserEvent({required this.userId, required this.userType});

  @override
  List<Object?> get props => [userId, userType];
}

// Data update events for real-time streams
class PatientsUpdated extends UsersEvent {
  final List<PatientEntity> patients;

  const PatientsUpdated(this.patients);

  @override
  List<Object?> get props => [patients];
}

class DoctorsUpdated extends UsersEvent {
  final List<DoctorEntity> doctors;

  const DoctorsUpdated(this.doctors);

  @override
  List<Object?> get props => [doctors];
}
