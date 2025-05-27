import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../entities/dossier_files_entity.dart';
import '../repositories/dossier_medical_repository.dart';

class AddFileToDossier {
  final DossierMedicalRepository repository;

  AddFileToDossier(this.repository);

  Future<Either<Failure, DossierFilesEntity>> call({
    required String patientId,
    required String filePath,
    required String description,
  }) async {
    return await repository.addFileToDossier(
      patientId: patientId,
      filePath: filePath,
      description: description,
    );
  }
}