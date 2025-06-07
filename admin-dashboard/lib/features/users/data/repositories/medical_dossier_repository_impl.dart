import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/medical_dossier_entity.dart';
import '../../domain/repositories/medical_dossier_repository.dart';
import '../datasources/medical_dossier_remote_datasource.dart';

class MedicalDossierRepositoryImpl implements MedicalDossierRepository {
  final MedicalDossierRemoteDataSource remoteDataSource;

  const MedicalDossierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, MedicalDossierEntity>> getMedicalDossier({
    required String patientId,
  }) async {
    try {
      final result = await remoteDataSource.getMedicalDossier(
        patientId: patientId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasMedicalDossier({
    required String patientId,
  }) async {
    try {
      final result = await remoteDataSource.hasMedicalDossier(
        patientId: patientId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }
}
