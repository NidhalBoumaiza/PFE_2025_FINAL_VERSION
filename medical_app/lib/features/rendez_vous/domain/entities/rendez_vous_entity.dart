import 'package:equatable/equatable.dart';

class RendezVousEntity extends Equatable {
  final String? id; // Auto-generated by Firestore
  final String? patientId; // Optional patient ID
  final String? doctorId; // Optional doctor ID
  final String? patientName; // Optional patient name
  final String? doctorName; // Optional doctor name
  final String? speciality; // Optional speciality
  final DateTime startTime; // Required start time
  final DateTime? endTime; // End time based on doctor's appointment duration
  final String status; // Required status: 'pending', 'accepted', 'refused'

  const RendezVousEntity({
    this.id,
    this.patientId,
    this.doctorId,
    this.patientName,
    this.doctorName,
    this.speciality,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  factory RendezVousEntity.create({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    String? speciality,
    required DateTime startTime,
    DateTime? endTime,
    required String status,
  }) {
    return RendezVousEntity(
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
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    doctorId,
    patientName,
    doctorName,
    speciality,
    startTime,
    endTime,
    status,
  ];
}