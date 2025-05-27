import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/dossier_medical/data/datasources/dossier_medical_remote_datasource.dart';
import 'package:medical_app/features/dossier_medical/domain/entities/dossier_files_entity.dart';
import 'package:medical_app/features/dossier_medical/domain/repositories/dossier_medical_repository.dart';

class DossierMedicalRepositoryImpl implements DossierMedicalRepository {
  final DossierMedicalRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DossierMedicalRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DossierFilesEntity>> getDossierMedical({
    required String patientId,
    required String? doctorId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteDossier = await remoteDataSource.getDossierMedical(
          patientId: patientId,
          doctorId: doctorId,
        );
        return Right(remoteDossier);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, DossierFilesEntity>> addFileToDossier({
    required String patientId,
    required String filePath,
    required String description,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final file = File(filePath);
        if (!file.existsSync()) {
          return const Left(FileFailure(message: 'File does not exist'));
        }

        final remoteDossier = await remoteDataSource.addFileToDossier(
          patientId: patientId,
          file: file,
          description: description,
        );
        return Right(remoteDossier);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(FileFailure(message: 'Error handling file: $e'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, DossierFilesEntity>> addFilesToDossier({
    required String patientId,
    required List<String> filePaths,
    required Map<String, String> descriptions,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final files = <File>[];
        for (final filePath in filePaths) {
          final file = File(filePath);
          if (!file.existsSync()) {
            return Left(FileFailure(message: 'File does not exist: $filePath'));
          }
          files.add(file);
        }

        final remoteDossier = await remoteDataSource.addFilesToDossier(
          patientId: patientId,
          files: files,
          descriptions: descriptions,
        );
        return Right(remoteDossier);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(FileFailure(message: 'Error handling files: $e'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFile({
    required String patientId,
    required String fileId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteFile(patientId: patientId, fileId: fileId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateFileDescription({
    required String patientId,
    required String fileId,
    required String description,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateFileDescription(
          patientId: patientId,
          fileId: fileId,
          description: description,
        );
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasDossierMedical({
    required String patientId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.hasDossierMedical(
          patientId: patientId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkDoctorAccessToPatientFiles({
    required String doctorId,
    required String patientId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final hasAccess = await remoteDataSource
            .checkDoctorAccessToPatientFiles(
              doctorId: doctorId,
              patientId: patientId,
            );
        return Right(hasAccess);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }
}
