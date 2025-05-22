import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_local_data_source.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_remote_data_source.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';
import '../models/RendezVous.dart';

class RendezVousRepositoryImpl implements RendezVousRepository {
  final RendezVousRemoteDataSource remoteDataSource;
  final RendezVousLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  RendezVousRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<RendezVousEntity>>> getRendezVous({
    String? patientId,
    String? doctorId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final rendezVousModels = await remoteDataSource.getRendezVous(
          patientId: patientId,
          doctorId: doctorId,
        );
        final rendezVousEntities = rendezVousModels
            .map((model) => RendezVousEntity(
          id: model.id,
          patientId: model.patientId,
          doctorId: model.doctorId,
          patientName: model.patientName,
          doctorName: model.doctorName,
          speciality: model.speciality,
          startTime: model.startTime,
          endTime: model.endTime,
          status: model.status,
        ))
            .toList();
        return Right(rendezVousEntities);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      try {
        final cachedRendezVous = await localDataSource.getCachedRendezVous();
        final rendezVousEntities = cachedRendezVous
            .map((model) => RendezVousEntity(
          id: model.id,
          patientId: model.patientId,
          doctorId: model.doctorId,
          patientName: model.patientName,
          doctorName: model.doctorName,
          speciality: model.speciality,
          startTime: model.startTime,
          endTime: model.endTime,
          status: model.status,
        ))
            .toList();
        return Right(rendezVousEntities);
      } on EmptyCacheException {
        return Left(EmptyCacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> updateRendezVousStatus(
      String rendezVousId,
      String status,
      String patientId,
      String doctorId,
      String patientName,
      String doctorName,
      ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateRendezVousStatus(
          rendezVousId,
          status,
          patientId,
          doctorId,
          patientName,
          doctorName,
        );
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> createRendezVous(
      RendezVousEntity rendezVous) async {
    if (await networkInfo.isConnected) {
      try {
        final rendezVousModel = RendezVousModel(
          id: rendezVous.id,
          patientId: rendezVous.patientId,
          doctorId: rendezVous.doctorId,
          patientName: rendezVous.patientName,
          doctorName: rendezVous.doctorName,
          speciality: rendezVous.speciality,
          startTime: rendezVous.startTime,
          endTime: rendezVous.endTime,
          status: rendezVous.status,
        );
        await remoteDataSource.createRendezVous(rendezVousModel);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<MedecinEntity>>> getDoctorsBySpecialty(
      String specialty,
      DateTime startTime,
      ) async {
    if (await networkInfo.isConnected) {
      try {
        final doctors = await remoteDataSource.getDoctorsBySpecialty(
          specialty,
          startTime,
        );
        return Right(doctors);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> assignDoctorToRendezVous(
      String rendezVousId,
      String doctorId,
      String doctorName,
      ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.assignDoctorToRendezVous(
          rendezVousId,
          doctorId,
          doctorName,
        );
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}