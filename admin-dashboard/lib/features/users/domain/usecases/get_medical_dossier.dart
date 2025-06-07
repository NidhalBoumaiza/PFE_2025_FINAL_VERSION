import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medical_dossier_entity.dart';
import '../repositories/medical_dossier_repository.dart';

class GetMedicalDossier
    implements
        UseCaseWithParams<MedicalDossierEntity, GetMedicalDossierParams> {
  final MedicalDossierRepository repository;

  const GetMedicalDossier(this.repository);

  @override
  Future<Either<Failure, MedicalDossierEntity>> call(
    GetMedicalDossierParams params,
  ) async {
    return await repository.getMedicalDossier(patientId: params.patientId);
  }
}

class GetMedicalDossierParams {
  final String patientId;

  const GetMedicalDossierParams({required this.patientId});
}
