import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../entities/dossier_files_entity.dart';
import '../repositories/dossier_medical_repository.dart';

class AddFilesToDossier {
  final DossierMedicalRepository repository;

  AddFilesToDossier(this.repository);

  Future<Either<Failure, DossierFilesEntity>> call({
    required String patientId,
    required List<String> filePaths,
    required Map<String, String> descriptions,
  }) async {
    return await repository.addFilesToDossier(
      patientId: patientId,
      filePaths: filePaths,
      descriptions: descriptions,
    );
  }
}