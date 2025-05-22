import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class SetupFCMUseCase {
  final NotificationRepository repository;

  SetupFCMUseCase(this.repository);

  Future<Either<Failure, String?>> call() async {
    return await repository.setupFCM();
  }
} 