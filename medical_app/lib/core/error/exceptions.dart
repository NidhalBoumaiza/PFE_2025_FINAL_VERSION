import 'package:equatable/equatable.dart';

/// A general server-related exception with a message.
class ServerException extends Equatable implements Exception {
  final String message;

  ServerException([this.message = 'Erreur du serveur']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when the cache is empty.
class EmptyCacheException extends Equatable implements Exception {
  final String message;

  EmptyCacheException([this.message = 'Aucune donnée trouvée en cache']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when there's no internet connection.
class OfflineException extends Equatable implements Exception {
  final String message;

  OfflineException([this.message = 'Pas de connexion Internet']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown for server-specific error messages.
class ServerMessageException extends Equatable implements Exception {
  final String message;

  ServerMessageException([this.message = 'Erreur du serveur']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown for unauthorized access.
class UnauthorizedException extends Equatable implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'Accès non autorisé']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when an API call times out.
class TimeoutException extends Equatable implements Exception {
  final String message;

  const TimeoutException([this.message = 'La requête a expiré']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown for authentication-specific errors.
class AuthException extends Equatable implements Exception {
  final String message;

  const AuthException([this.message = 'Erreur d\'authentification']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when email or phone number is already used.
class UsedEmailOrPhoneNumberException extends Equatable implements Exception {
  final String message;

  const UsedEmailOrPhoneNumberException([
    this.message = 'Email ou numéro de téléphone déjà utilisé',
  ]);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when an inactive account's validation code has expired.
class YouHaveToCreateAccountAgainException extends Equatable
    implements Exception {
  final String message;

  const YouHaveToCreateAccountAgainException([
    this.message =
        'Compte inactif et code de validation expiré. Veuillez créer un nouveau compte.',
  ]);

  @override
  List<Object?> get props => [message];
}
