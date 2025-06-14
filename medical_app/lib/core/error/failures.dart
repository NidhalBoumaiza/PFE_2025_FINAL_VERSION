import 'package:equatable/equatable.dart';
import 'package:get/get.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({this.message = ''});

  @override
  List<Object> get props => [message];
}

class OfflineFailure extends Failure {
  OfflineFailure() : super(message: 'Pas de connexion Internet');
}

class ServerFailure extends Failure {
  const ServerFailure({String message = 'Une erreur de serveur est survenue'})
    : super(message: message);
}

class EmptyCacheFailure extends Failure {
  EmptyCacheFailure() : super(message: 'Aucune donnée trouvée en cache');
}

class ServerMessageFailure extends Failure {
  final String customMessage;

  ServerMessageFailure(this.customMessage) : super(message: customMessage);
}

class UnauthorizedFailure extends Failure {
  UnauthorizedFailure() : super(message: 'Accès non autorisé');
}

class TimeoutFailure extends Failure {
  TimeoutFailure() : super(message: 'La requête a expiré');
}

class AuthFailure extends Failure {
  final String? customMessage;

  AuthFailure([this.customMessage])
    : super(message: customMessage ?? 'Erreur d\'authentification');
}

class UsedEmailOrPhoneNumberFailure extends Failure {
  final String? customMessage;

  UsedEmailOrPhoneNumberFailure([this.customMessage])
    : super(
        message: customMessage ?? 'Email ou numéro de téléphone déjà utilisé',
      );
}

class YouHaveToCreateAccountAgainFailure extends Failure {
  final String? customMessage;

  YouHaveToCreateAccountAgainFailure([this.customMessage])
    : super(
        message:
            customMessage ??
            'Compte inactif et code de validation expiré. Veuillez créer un nouveau compte.',
      );
}

class CacheFailure extends Failure {
  const CacheFailure({String message = 'Erreur de mise en cache'})
    : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Erreur de réseau'})
    : super(message: message);
}

class FileFailure extends Failure {
  const FileFailure({
    String message = 'Erreur lors de l\'opération sur le fichier',
  }) : super(message: message);
}
