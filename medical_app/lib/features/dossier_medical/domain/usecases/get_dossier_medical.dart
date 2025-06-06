import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../entities/dossier_files_entity.dart';
import '../repositories/dossier_medical_repository.dart';

class GetDossierMedical {
  final DossierMedicalRepository repository;

  GetDossierMedical(this.repository);

  Future<Either<Failure, DossierFilesEntity>> call({
    required String patientId,
    String? doctorId,
  }) async {
    return await repository.getDossierMedical(
      patientId: patientId,
      doctorId: doctorId,
    );
  }
}
