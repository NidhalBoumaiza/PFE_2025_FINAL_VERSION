part of 'prescription_bloc.dart';

abstract class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();

  @override
  List<Object?> get props => [];
}

class CreatePrescription extends PrescriptionEvent {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final List<MedicationEntity> medications;
  final String? note;

  const CreatePrescription({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.medications,
    this.note,
  });

  @override
  List<Object?> get props => [
    appointmentId,
    patientId,
    patientName,
    doctorId,
    doctorName,
    medications,
    note,
  ];
}

class EditPrescription extends PrescriptionEvent {
  final PrescriptionEntity prescription;

  const EditPrescription({required this.prescription});

  @override
  List<Object> get props => [prescription];
}

class GetPatientPrescriptions extends PrescriptionEvent {
  final String patientId;

  const GetPatientPrescriptions({required this.patientId});

  @override
  List<Object> get props => [patientId];
}

class GetDoctorPrescriptions extends PrescriptionEvent {
  final String doctorId;

  const GetDoctorPrescriptions({required this.doctorId});

  @override
  List<Object> get props => [doctorId];
}

class GetPrescriptionById extends PrescriptionEvent {
  final String prescriptionId;

  const GetPrescriptionById({required this.prescriptionId});

  @override
  List<Object> get props => [prescriptionId];
}

class GetPrescriptionByAppointmentId extends PrescriptionEvent {
  final String appointmentId;

  const GetPrescriptionByAppointmentId({required this.appointmentId});

  @override
  List<Object> get props => [appointmentId];
}

class UpdatePrescription extends PrescriptionEvent {
  final PrescriptionEntity prescription;

  const UpdatePrescription({required this.prescription});

  @override
  List<Object> get props => [prescription];
} 