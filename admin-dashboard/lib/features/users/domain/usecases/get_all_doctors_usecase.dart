import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/doctor_entity.dart';
import '../repositories/users_repository.dart';

class GetAllDoctorsUseCase implements UseCase<List<DoctorEntity>> {
  final UsersRepository repository;

  GetAllDoctorsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DoctorEntity>>> call() {
    return repository.getAllDoctors();
  }
}
