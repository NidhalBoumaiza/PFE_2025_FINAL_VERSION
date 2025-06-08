import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_data_source.dart';
import '../models/patient_model.dart';
import '../models/doctor_model.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;

  UsersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PatientEntity>>> getAllPatients() async {
    try {
      final patients = await remoteDataSource.getPatients();
      return Right(patients);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get patients: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DoctorEntity>>> getAllDoctors() async {
    try {
      final doctors = await remoteDataSource.getDoctors();
      return Right(doctors);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get doctors: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<PatientEntity>>> getPatientsStream() {
    try {
      return remoteDataSource.getPatientsStream().map(
        (patients) => Right(patients),
      );
    } catch (e) {
      return Stream.value(
        Left(ServerFailure(message: 'Failed to get patients stream: $e')),
      );
    }
  }

  @override
  Stream<Either<Failure, List<DoctorEntity>>> getDoctorsStream() {
    try {
      return remoteDataSource.getDoctorsStream().map(
        (doctors) => Right(doctors),
      );
    } catch (e) {
      return Stream.value(
        Left(ServerFailure(message: 'Failed to get doctors stream: $e')),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> refreshAllUsers() async {
    try {
      await remoteDataSource.refreshData();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to refresh users: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteUser(
    String userId,
    String userType,
  ) async {
    try {
      await remoteDataSource.deleteUser(userId, userType);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete user: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getUserStatistics() async {
    try {
      final statistics = await remoteDataSource.getUserStatistics();
      return Right(statistics);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get user statistics: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUserAppointmentCount(
    String userId,
    String userType,
  ) async {
    try {
      final count = await remoteDataSource.getUserAppointmentCount(
        userId,
        userType,
      );
      return Right(count);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to get user appointment count: $e'),
      );
    }
  }
}
