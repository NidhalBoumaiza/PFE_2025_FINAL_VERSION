import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';

class RendezVousModel extends RendezVousEntity {
  RendezVousModel({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    String? speciality,
    required DateTime startTime,
    DateTime? endTime,
    required String status,
  }) : super(
    id: id,
    patientId: patientId,
    doctorId: doctorId,
    patientName: patientName,
    doctorName: doctorName,
    speciality: speciality,
    startTime: startTime,
    endTime: endTime,
    status: status,
  );

  factory RendezVousModel.fromJson(Map<String, dynamic> json) {
    return RendezVousModel(
      id: json['id'] as String?,
      patientId: json['patientId'] as String?,
      doctorId: json['doctorId'] as String?,
      patientName: json['patientName'] as String?,
      doctorName: json['doctorName'] as String?,
      speciality: json['speciality'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      status: json['status'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (patientId != null) 'patientId': patientId,
      if (doctorId != null) 'doctorId': doctorId,
      if (patientName != null) 'patientName': patientName,
      if (doctorName != null) 'doctorName': doctorName,
      if (speciality != null) 'speciality': speciality,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      'status': status,
    };
  }
}