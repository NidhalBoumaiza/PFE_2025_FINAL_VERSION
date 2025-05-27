import 'package:dartz/dartz.dart';
import '../entities/dossier_medical_entity.dart';
import '../repositories/dossier_medical_repository.dart';
import '../../../../core/error/failures.dart';

class CheckDoctorAccess {
  final DossierMedicalRepository repository;

  CheckDoctorAccess(this.repository);

  Future<Either<Failure, bool>> call({
    required String doctorId,
    required String patientId,
  }) async {
    return await repository.checkDoctorAccessToPatientFiles(
      doctorId: doctorId,
      patientId: patientId,
    );
  }
}
