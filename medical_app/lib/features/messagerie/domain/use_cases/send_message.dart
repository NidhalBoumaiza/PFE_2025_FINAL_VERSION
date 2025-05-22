import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

class SendMessageUseCase {
  final MessagingRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, Unit>> call(MessageModel message, File? file) async {
    return await repository.sendMessage(message, file);
  }
}