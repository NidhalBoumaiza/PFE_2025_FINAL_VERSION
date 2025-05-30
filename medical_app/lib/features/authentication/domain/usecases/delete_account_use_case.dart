import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

class DeleteAccountUseCase {
  final AuthRepository repository;

  DeleteAccountUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String userId,
    required String password,
  }) async {
    return await repository.deleteAccount(userId: userId, password: password);
  }
}
