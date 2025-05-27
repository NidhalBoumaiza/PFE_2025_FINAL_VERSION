import 'package:equatable/equatable.dart';
import 'medical_file_entity.dart';

/// Represents the array of medical files stored as the 'dossierFiles' field
/// in a patient's document in the Firestore 'patients' collection.
class DossierFilesEntity extends Equatable {
  /// List of medical files stored in the patient's document.
  final List<MedicalFileEntity> files;

  const DossierFilesEntity({
    required this.files,
  });

  /// Indicates if the dossier has no files.
  bool get isEmpty => files.isEmpty;

  /// Indicates if the dossier has files.
  bool get isNotEmpty => files.isNotEmpty;

  @override
  List<Object?> get props => [files];
}