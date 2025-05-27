import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../repositories/dossier_medical_repository.dart';

class DeleteFile {
  final DossierMedicalRepository repository;

  DeleteFile(this.repository);

  Future<Either<Failure, Unit>> call({
    required String patientId,
    required String fileId,
  }) async {
    return await repository.deleteFile(
      patientId: patientId,
      fileId: fileId,
    );
  }
}