import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';

class EmailService {
  // Using SendGrid API which is better for transactional emails
  static const String _apiUrl = 'https://api.sendgrid.com/v3/mail/send';
  static const String _fromEmail =
      'nidhalbmz123@gmail.com'; // Your verified sender email
  static const String _fromName = 'Medical App';

  /// Send verification code email using SendGrid API
  static Future<bool> sendVerificationCode(
    String recipientEmail,
    String verificationCode,
    String subject,
  ) async {
    try {
      // Prepare the email data for SendGrid format
      String htmlContent = _generateEmailContent(subject, verificationCode);
      String textContent = _generateTextContent(subject, verificationCode);

      final Map<String, dynamic> emailData = {
        'personalizations': [
          {
            'to': [
              {'email': recipientEmail},
            ],
            'subject': subject,
          },
        ],
        'from': {'email': _fromEmail, 'name': _fromName},
        'content': [
          {'type': 'text/plain', 'value': textContent},
          {'type': 'text/html', 'value': htmlContent},
        ],
      };

      // Send email using SendGrid API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${AppConstants.mailApiKey}', // This should be your SendGrid API key
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 202) {
        // SendGrid returns 202 for success
        print('Email sent successfully via SendGrid: ${response.body}');
        return true;
      } else {
        print(
          'Failed to send email via SendGrid: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error sending email via SendGrid: $e');
      return false;
    }
  }

  /// Generate HTML content based on email type
  static String _generateEmailContent(String subject, String verificationCode) {
    switch (subject) {
      case 'Compte Activé':
        return '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;">
          <div style="background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h2 style="color: #2E7D32; text-align: center; margin-bottom: 30px;">Compte Activé ✅</h2>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">Bonjour,</p>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Félicitations ! Votre compte sur notre plateforme médicale est maintenant activé.
            </p>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Vous pouvez désormais accéder à tous nos services médicaux.
            </p>
            <div style="text-align: center; margin: 30px 0;">
              <p style="font-size: 14px; color: #666;">Merci de votre confiance</p>
            </div>
          </div>
        </div>
        ''';

      case 'Activation de compte':
        return '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;">
          <div style="background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h2 style="color: #2E7D32; text-align: center; margin-bottom: 30px;">Activation de compte</h2>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">Bonjour,</p>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Merci de créer un compte sur notre plateforme médicale.
            </p>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Voici votre code d'activation :
            </p>
            <div style="text-align: center; margin: 30px 0;">
              <span style="font-size: 32px; font-weight: bold; color: #2E7D32; background-color: #E8F5E8; padding: 15px 25px; border-radius: 8px; display: inline-block; letter-spacing: 5px;">$verificationCode</span>
            </div>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Veuillez saisir ce code dans l'application pour activer votre compte.
            </p>
            <p style="font-size: 14px; color: #666; text-align: center; margin-top: 30px;">
              Ce code expire dans 60 minutes.
            </p>
          </div>
        </div>
        ''';

      case 'Mot de passe oublié':
        return '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;">
          <div style="background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h2 style="color: #2E7D32; text-align: center; margin-bottom: 30px;">Réinitialisation du mot de passe</h2>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">Bonjour,</p>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Nous avons reçu une demande de réinitialisation de votre mot de passe.
            </p>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Voici votre code de vérification :
            </p>
            <div style="text-align: center; margin: 30px 0;">
              <span style="font-size: 32px; font-weight: bold; color: #2E7D32; background-color: #E8F5E8; padding: 15px 25px; border-radius: 8px; display: inline-block; letter-spacing: 5px;">$verificationCode</span>
            </div>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Utilisez ce code pour réinitialiser votre mot de passe.
            </p>
            <p style="font-size: 14px; color: #666; text-align: center; margin-top: 30px;">
              Ce code expire dans 60 minutes.
            </p>
          </div>
        </div>
        ''';

      case 'Changer mot de passe':
        return '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;">
          <div style="background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h2 style="color: #2E7D32; text-align: center; margin-bottom: 30px;">Changement de mot de passe</h2>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">Bonjour,</p>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Vous avez demandé à changer votre mot de passe.
            </p>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Voici votre code de vérification :
            </p>
            <div style="text-align: center; margin: 30px 0;">
              <span style="font-size: 32px; font-weight: bold; color: #2E7D32; background-color: #E8F5E8; padding: 15px 25px; border-radius: 8px; display: inline-block; letter-spacing: 5px;">$verificationCode</span>
            </div>
            <p style="font-size: 16px; line-height: 1.6; color: #333;">
              Utilisez ce code pour confirmer le changement de votre mot de passe.
            </p>
            <p style="font-size: 14px; color: #666; text-align: center; margin-top: 30px;">
              Ce code expire dans 60 minutes.
            </p>
          </div>
        </div>
        ''';

      default:
        return '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <p>Votre code de vérification est: <b>$verificationCode</b></p>
        </div>
        ''';
    }
  }

  /// Generate plain text content based on email type
  static String _generateTextContent(String subject, String verificationCode) {
    switch (subject) {
      case 'Compte Activé':
        return '''
Bonjour,

Félicitations ! Votre compte sur notre plateforme médicale est maintenant activé.

Vous pouvez désormais accéder à tous nos services médicaux.

Merci de votre confiance.
        ''';

      case 'Activation de compte':
        return '''
Bonjour,

Merci de créer un compte sur notre plateforme médicale.

Voici votre code d'activation : $verificationCode

Veuillez saisir ce code dans l'application pour activer votre compte.

Ce code expire dans 60 minutes.
        ''';

      case 'Mot de passe oublié':
        return '''
Bonjour,

Nous avons reçu une demande de réinitialisation de votre mot de passe.

Voici votre code de vérification : $verificationCode

Utilisez ce code pour réinitialiser votre mot de passe.

Ce code expire dans 60 minutes.
        ''';

      case 'Changer mot de passe':
        return '''
Bonjour,

Vous avez demandé à changer votre mot de passe.

Voici votre code de vérification : $verificationCode

Utilisez ce code pour confirmer le changement de votre mot de passe.

Ce code expire dans 60 minutes.
        ''';

      default:
        return 'Votre code de vérification est: $verificationCode';
    }
  }
}
