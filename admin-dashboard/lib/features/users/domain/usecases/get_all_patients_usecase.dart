import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/patient_entity.dart';
import '../repositories/users_repository.dart';

class GetAllPatientsUseCase implements UseCase<List<PatientEntity>> {
  final UsersRepository repository;

  GetAllPatientsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PatientEntity>>> call() {
    return repository.getAllPatients();
  }
}
