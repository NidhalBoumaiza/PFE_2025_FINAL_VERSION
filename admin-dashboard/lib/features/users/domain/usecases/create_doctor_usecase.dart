import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/doctor_entity.dart';
import '../repositories/users_repository.dart';

class CreateDoctorUseCase {
  final UsersRepository repository;

  CreateDoctorUseCase(this.repository);

  Future<Either<Failure, Unit>> call(
    DoctorEntity doctor,
    String password,
  ) async {
    return await repository.createDoctor(doctor, password);
  }
}
