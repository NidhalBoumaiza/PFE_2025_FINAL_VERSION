import 'package:equatable/equatable.dart';
import 'package:get/get.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({this.message = ''});

  @override
  List<Object> get props => [message];
}

class OfflineFailure extends Failure {
  @override
  String get message => 'offline_failure_message'.tr;
}

class ServerFailure extends Failure {
  const ServerFailure({String message = 'Server error occurred'})
    : super(message: message);
}

class EmptyCacheFailure extends Failure {
  @override
  String get message => 'empty_cache_failure_message'.tr;
}

class ServerMessageFailure extends Failure {
  final String customMessage;

  ServerMessageFailure(this.customMessage);

  @override
  String get message => customMessage;
}

class UnauthorizedFailure extends Failure {
  @override
  String get message => 'unauthorized_failure_message'.tr;
}

class TimeoutFailure extends Failure {
  @override
  String get message => 'timeout_failure_message'.tr;
}

class AuthFailure extends Failure {
  final String? customMessage;

  AuthFailure([this.customMessage]);

  @override
  String get message => customMessage ?? 'auth_failure_message'.tr;
}

class UsedEmailOrPhoneNumberFailure extends Failure {
  final String? customMessage;

  UsedEmailOrPhoneNumberFailure([this.customMessage]);

  @override
  String get message => customMessage ?? 'email_or_phone_number_used'.tr;
}

class YouHaveToCreateAccountAgainFailure extends Failure {
  final String? customMessage;

  YouHaveToCreateAccountAgainFailure([this.customMessage]);

  @override
  String get message => customMessage ?? 'create_account_again'.tr;
}

class CacheFailure extends Failure {
  const CacheFailure({String message = 'Cache failure occurred'})
    : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network failure occurred'})
    : super(message: message);
}

class FileFailure extends Failure {
  const FileFailure({String message = 'File operation failure occurred'})
    : super(message: message);
}
