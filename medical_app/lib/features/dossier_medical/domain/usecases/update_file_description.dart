import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../repositories/dossier_medical_repository.dart';

class UpdateFileDescription {
  final DossierMedicalRepository repository;

  UpdateFileDescription(this.repository);

  Future<Either<Failure, Unit>> call({
    required String patientId,
    required String fileId,
    required String description,
  }) async {
    return await repository.updateFileDescription(
      patientId: patientId,
      fileId: fileId,
      description: description,
    );
  }
}