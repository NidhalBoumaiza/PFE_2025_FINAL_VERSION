import 'package:equatable/equatable.dart';

class MedicationEntity extends Equatable {
  final String id;
  final String name;
  final String dosage;
  final String instructions;

  const MedicationEntity({
    required this.id,
    required this.name,
    required this.dosage,
    required this.instructions,
  });

  @override
  List<Object?> get props => [id, name, dosage, instructions];

  factory MedicationEntity.fromJson(Map<String, dynamic> json) {
    return MedicationEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      instructions: json['instructions'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'instructions': instructions,
    };
  }
}

class PrescriptionEntity extends Equatable {
  final String id;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final List<MedicationEntity> medications;
  final String? note;

  const PrescriptionEntity({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.medications,
    this.note,
  });

  @override
  List<Object?> get props => [
    id, 
    appointmentId, 
    patientId, 
    patientName, 
    doctorId, 
    doctorName, 
    date, 
    medications, 
    note
  ];

  // Factory method to create a new prescription
  factory PrescriptionEntity.create({
    required String id,
    required String appointmentId,
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required List<MedicationEntity> medications,
    String? note,
  }) {
    return PrescriptionEntity(
      id: id,
      appointmentId: appointmentId,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      date: DateTime.now(),
      medications: medications,
      note: note,
    );
  }
} 