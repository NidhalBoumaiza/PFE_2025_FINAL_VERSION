import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/prescription_entity.dart';

class PrescriptionModel extends PrescriptionEntity {
  const PrescriptionModel({
    required String id,
    required String appointmentId,
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required DateTime date,
    required List<MedicationEntity> medications,
    String? note,
  }) : super(
          id: id,
          appointmentId: appointmentId,
          patientId: patientId,
          patientName: patientName,
          doctorId: doctorId,
          doctorName: doctorName,
          date: date,
          medications: medications,
          note: note,
        );

  // Convert to JSON for API or storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': date.toIso8601String(),
      'medications': medications.map((m) => m.toJson()).toList(),
      'note': note,
    };
  }

  // Create from JSON
  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    List<MedicationEntity> meds = [];
    if (json['medications'] != null) {
      final medications = json['medications'] as List;
      meds = medications
          .map((m) => MedicationEntity.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return PrescriptionModel(
      id: json['id'] as String,
      appointmentId: json['appointmentId'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String,
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.parse(json['date'] as String),
      medications: meds,
      note: json['note'] as String?,
    );
  }

  // Create from entity
  factory PrescriptionModel.fromEntity(PrescriptionEntity entity) {
    return PrescriptionModel(
      id: entity.id,
      appointmentId: entity.appointmentId,
      patientId: entity.patientId,
      patientName: entity.patientName,
      doctorId: entity.doctorId,
      doctorName: entity.doctorName,
      date: entity.date,
      medications: entity.medications,
      note: entity.note,
    );
  }
} 