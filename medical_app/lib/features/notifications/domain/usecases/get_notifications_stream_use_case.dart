import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsStreamUseCase {
  final NotificationRepository repository;

  GetNotificationsStreamUseCase(this.repository);

  Stream<List<NotificationEntity>> call({required String userId}) {
    return repository.notificationsStream(userId);
  }
} 