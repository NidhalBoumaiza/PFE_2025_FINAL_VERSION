import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/users_repository.dart';

class DeleteUserUseCase {
  final UsersRepository repository;

  DeleteUserUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String userId, String userType) async {
    return await repository.deleteUser(userId, userType);
  }
}
