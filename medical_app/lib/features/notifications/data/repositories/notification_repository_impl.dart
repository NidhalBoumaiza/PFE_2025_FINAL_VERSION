import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

import '../../domain/repositories/notification_repository.dart';
import '../../utils/notification_utils.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final notifications = await remoteDataSource.getNotifications(userId);
        return Right(notifications);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendNotification({
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    required String recipientRole,
    String? appointmentId,
    String? prescriptionId,
    String? ratingId,
    Map<String, dynamic>? data,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendNotification(
          title: title,
          body: body,
          senderId: senderId,
          recipientId: recipientId,
          type: type,
          recipientRole: recipientRole,
          appointmentId: appointmentId,
          prescriptionId: prescriptionId,
          ratingId: ratingId,
          data: data,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markNotificationAsRead(notificationId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAllNotificationsAsRead(userId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteNotification(notificationId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadNotificationsCount(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getUnreadNotificationsCount(userId);
        return Right(count);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, String?>> setupFCM() async {
    if (await networkInfo.isConnected) {
      try {
        final token = await remoteDataSource.setupFCM();
        return Right(token);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveFCMToken(String userId, String token) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.saveFCMToken(userId, token);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Stream<List<NotificationEntity>> notificationsStream(String userId) {
    return remoteDataSource.notificationsStream(userId);
  }
}