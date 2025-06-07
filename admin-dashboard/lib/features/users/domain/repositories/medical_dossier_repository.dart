import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/medical_dossier_entity.dart';

abstract class MedicalDossierRepository {
  Future<Either<Failure, MedicalDossierEntity>> getMedicalDossier({
    required String patientId,
  });

  Future<Either<Failure, bool>> hasMedicalDossier({required String patientId});
}
