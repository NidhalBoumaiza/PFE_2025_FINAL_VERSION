part of 'rendez_vous_bloc.dart';

abstract class RendezVousEvent extends Equatable {
  const RendezVousEvent();

  @override
  List<Object?> get props => [];
}

class FetchRendezVous extends RendezVousEvent {
  final String? patientId;
  final String? doctorId;
  final String? appointmentId;

  const FetchRendezVous({this.patientId, this.doctorId, this.appointmentId});

  @override
  List<Object?> get props => [patientId, doctorId, appointmentId];
}

class UpdateRendezVousStatus extends RendezVousEvent {
  final String rendezVousId;
  final String status;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;

  const UpdateRendezVousStatus({
    required this.rendezVousId,
    required this.status,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
  });

  @override
  List<Object> get props => [
    rendezVousId,
    status,
    patientId,
    doctorId,
    patientName,
    doctorName,
  ];
}

class CreateRendezVous extends RendezVousEvent {
  final RendezVousEntity rendezVous;

  const CreateRendezVous(this.rendezVous);

  @override
  List<Object> get props => [rendezVous];
}

class FetchDoctorsBySpecialty extends RendezVousEvent {
  final String specialty;
  final DateTime startTime;

  const FetchDoctorsBySpecialty(this.specialty, this.startTime);

  @override
  List<Object> get props => [specialty, startTime];
}

class AssignDoctorToRendezVous extends RendezVousEvent {
  final String rendezVousId;
  final String doctorId;
  final String doctorName;

  const AssignDoctorToRendezVous(
      this.rendezVousId,
      this.doctorId,
      this.doctorName,
      );

  @override
  List<Object> get props => [rendezVousId, doctorId, doctorName];
}

class CheckAndUpdatePastAppointments extends RendezVousEvent {
  final String userId;
  final String userRole;

  const CheckAndUpdatePastAppointments({
    required this.userId,
    required this.userRole,
  });

  @override
  List<Object> get props => [userId, userRole];
}