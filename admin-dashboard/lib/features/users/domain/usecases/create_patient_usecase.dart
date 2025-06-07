import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/patient_entity.dart';
import '../repositories/users_repository.dart';

class CreatePatientUseCase {
  final UsersRepository repository;

  CreatePatientUseCase(this.repository);

  Future<Either<Failure, Unit>> call(
    PatientEntity patient,
    String password,
  ) async {
    return await repository.createPatient(patient, password);
  }
}
