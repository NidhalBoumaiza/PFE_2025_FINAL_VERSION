import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String email,
    required String newPassword,
    required int verificationCode,
  }) async {
    return await repository.changePassword(
      email: email,
      newPassword: newPassword,
      verificationCode: verificationCode,
    );
  }
}