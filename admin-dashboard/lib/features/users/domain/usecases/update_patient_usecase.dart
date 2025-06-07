import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/patient_entity.dart';
import '../repositories/users_repository.dart';

class UpdatePatientUseCase {
  final UsersRepository repository;

  UpdatePatientUseCase(this.repository);

  Future<Either<Failure, Unit>> call(PatientEntity patient) async {
    return await repository.updatePatient(patient);
  }
}
