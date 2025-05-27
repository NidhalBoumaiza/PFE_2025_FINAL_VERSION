import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../entities/dossier_files_entity.dart';

abstract class DossierMedicalRepository {
  Future<Either<Failure, DossierFilesEntity>> getDossierMedical({
    required String patientId,
    required String? doctorId,
  });
  Future<Either<Failure, DossierFilesEntity>> addFileToDossier({
    required String patientId,
    required String filePath,
    required String description,
  });
  Future<Either<Failure, DossierFilesEntity>> addFilesToDossier({
    required String patientId,
    required List<String> filePaths,
    required Map<String, String> descriptions,
  });
  Future<Either<Failure, Unit>> deleteFile({
    required String patientId,
    required String fileId,
  });
  Future<Either<Failure, Unit>> updateFileDescription({
    required String patientId,
    required String fileId,
    required String description,
  });
  Future<Either<Failure, bool>> hasDossierMedical({required String patientId});
  Future<Either<Failure, bool>> checkDoctorAccessToPatientFiles({
    required String doctorId,
    required String patientId,
  });
}
