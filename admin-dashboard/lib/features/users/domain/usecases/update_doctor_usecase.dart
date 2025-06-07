import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/doctor_entity.dart';
import '../repositories/users_repository.dart';

class UpdateDoctorUseCase {
  final UsersRepository repository;

  UpdateDoctorUseCase(this.repository);

  Future<Either<Failure, Unit>> call(DoctorEntity doctor) async {
    return await repository.updateDoctor(doctor);
  }
}
