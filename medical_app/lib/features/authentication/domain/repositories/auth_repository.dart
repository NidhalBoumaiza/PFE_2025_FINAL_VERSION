import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';

import '../../data/data sources/auth_remote_data_source.dart';

abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<Either<Failure, Unit>> createAccount({
    required UserEntity user,
    required String password,
  });
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });
  Future<Either<Failure, Unit>> updateUser(UserEntity user);
  Future<Either<Failure, Unit>> sendVerificationCode({
    required String email,
    required VerificationCodeType codeType,
  });
  Future<Either<Failure, Unit>> verifyCode({
    required String email,
    required int verificationCode,
    required VerificationCodeType codeType,
  });
  Future<Either<Failure, Unit>> changePassword({
    required String email,
    required String newPassword,
    required int verificationCode,
  });
  Future<Either<Failure, Unit>> updatePasswordDirect({
    required String email,
    required String currentPassword,
    required String newPassword,
  });
}
