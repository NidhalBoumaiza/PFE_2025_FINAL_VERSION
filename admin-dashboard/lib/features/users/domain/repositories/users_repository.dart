import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/patient_entity.dart';
import '../entities/doctor_entity.dart';

abstract class UsersRepository {
  Future<Either<Failure, List<PatientEntity>>> getAllPatients();
  Future<Either<Failure, List<DoctorEntity>>> getAllDoctors();
  Stream<Either<Failure, List<PatientEntity>>> getPatientsStream();
  Stream<Either<Failure, List<DoctorEntity>>> getDoctorsStream();
  Future<Either<Failure, Unit>> refreshAllUsers();

  // Only delete operation remains
  Future<Either<Failure, Unit>> deleteUser(String userId, String userType);

  // Statistics methods
  Future<Either<Failure, Map<String, int>>> getUserStatistics();
  Future<Either<Failure, int>> getUserAppointmentCount(
    String userId,
    String userType,
  );
}
