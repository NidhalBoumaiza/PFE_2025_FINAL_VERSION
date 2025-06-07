import 'package:equatable/equatable.dart';
import '../../domain/entities/medical_dossier_entity.dart';

abstract class MedicalDossierState extends Equatable {
  const MedicalDossierState();

  @override
  List<Object> get props => [];
}

class MedicalDossierInitial extends MedicalDossierState {
  const MedicalDossierInitial();
}

class MedicalDossierLoading extends MedicalDossierState {
  const MedicalDossierLoading();
}

class MedicalDossierLoaded extends MedicalDossierState {
  final MedicalDossierEntity dossier;
  final String patientId;

  const MedicalDossierLoaded({required this.dossier, required this.patientId});

  @override
  List<Object> get props => [dossier, patientId];
}

class MedicalDossierError extends MedicalDossierState {
  final String message;

  const MedicalDossierError({required this.message});

  @override
  List<Object> get props => [message];
}
