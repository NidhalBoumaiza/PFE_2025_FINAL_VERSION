import 'package:equatable/equatable.dart';

abstract class MedicalDossierEvent extends Equatable {
  const MedicalDossierEvent();

  @override
  List<Object> get props => [];
}

class GetMedicalDossierEvent extends MedicalDossierEvent {
  final String patientId;

  const GetMedicalDossierEvent({required this.patientId});

  @override
  List<Object> get props => [patientId];
}

class ClearMedicalDossierEvent extends MedicalDossierEvent {
  const ClearMedicalDossierEvent();
}
