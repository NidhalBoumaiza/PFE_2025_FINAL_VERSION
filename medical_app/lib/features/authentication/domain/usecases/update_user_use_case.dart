import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

class UpdateUserUseCase {
  final AuthRepository repository;

  UpdateUserUseCase(this.repository);

  Future<Either<Failure, Unit>> call(UserEntity user) async {
    print('🔧 UpdateUserUseCase: Starting update for user ${user.id}');
    print('🔧 UpdateUserUseCase: User data - ${user.toString()}');

    try {
      final result = await repository.updateUser(user);
      print('🔧 UpdateUserUseCase: Repository result - ${result.toString()}');
      return result;
    } catch (e) {
      print('🔧 UpdateUserUseCase: Exception caught - $e');
      rethrow;
    }
  }
}
