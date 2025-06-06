import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../repositories/dossier_medical_repository.dart';

class HasDossierMedical {
  final DossierMedicalRepository repository;

  HasDossierMedical(this.repository);

  Future<Either<Failure, bool>> call({
    required String patientId,
  }) async {
    return await repository.hasDossierMedical(patientId: patientId);
  }
}