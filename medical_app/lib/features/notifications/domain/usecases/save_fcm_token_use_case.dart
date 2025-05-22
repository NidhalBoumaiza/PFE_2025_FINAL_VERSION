import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class SaveFCMTokenUseCase {
  final NotificationRepository repository;

  SaveFCMTokenUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String userId,
    required String token,
  }) async {
    return await repository.saveFCMToken(userId, token);
  }
} 