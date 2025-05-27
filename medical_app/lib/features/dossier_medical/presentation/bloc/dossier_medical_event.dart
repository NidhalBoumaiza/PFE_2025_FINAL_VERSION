import 'package:equatable/equatable.dart';

abstract class DossierMedicalEvent extends Equatable {
  const DossierMedicalEvent();

  @override
  List<Object?> get props => [];
}

class FetchDossierMedicalEvent extends DossierMedicalEvent {
  final String patientId;
  final String? doctorId;

  const FetchDossierMedicalEvent({required this.patientId, this.doctorId});

  @override
  List<Object?> get props => [patientId, doctorId];
}

class CheckDossierMedicalExistsEvent extends DossierMedicalEvent {
  final String patientId;

  const CheckDossierMedicalExistsEvent({required this.patientId});

  @override
  List<Object?> get props => [patientId];
}

class UploadSingleFileEvent extends DossierMedicalEvent {
  final String patientId;
  final String filePath;
  final String description;

  const UploadSingleFileEvent({
    required this.patientId,
    required this.filePath,
    this.description = '',
  });

  @override
  List<Object?> get props => [patientId, filePath, description];
}

class UploadMultipleFilesEvent extends DossierMedicalEvent {
  final String patientId;
  final List<String> filePaths;
  final Map<String, String> descriptions;

  const UploadMultipleFilesEvent({
    required this.patientId,
    required this.filePaths,
    this.descriptions = const {},
  });

  @override
  List<Object?> get props => [patientId, filePaths, descriptions];
}

class DeleteFileEvent extends DossierMedicalEvent {
  final String patientId;
  final String fileId;

  const DeleteFileEvent({required this.patientId, required this.fileId});

  @override
  List<Object?> get props => [patientId, fileId];
}

class UpdateFileDescriptionEvent extends DossierMedicalEvent {
  final String patientId;
  final String fileId;
  final String description;

  const UpdateFileDescriptionEvent({
    required this.patientId,
    required this.fileId,
    required this.description,
  });

  @override
  List<Object?> get props => [patientId, fileId, description];
}
