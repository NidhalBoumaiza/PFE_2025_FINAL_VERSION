import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_local_data_source.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import '../models/RendezVous.dart';
import 'package:medical_app/core/services/location_service.dart';

abstract class RendezVousRemoteDataSource {
  Future<List<RendezVousModel>> getRendezVous({
    String? patientId,
    String? doctorId,
  });

  Future<void> updateRendezVousStatus(
    String rendezVousId,
    String status,
    String patientId,
    String doctorId,
    String patientName,
    String doctorName,
    String recipientRole,
  );

  Future<void> createRendezVous(RendezVousModel rendezVous);

  Future<List<MedecinEntity>> getDoctorsBySpecialty(
    String specialty,
    DateTime startTime, {
    double? searchRadiusKm,
    double? userLatitude,
    double? userLongitude,
  });

  Future<void> assignDoctorToRendezVous(
    String rendezVousId,
    String doctorId,
    String doctorName,
  );
}

class RendezVousRemoteDataSourceImpl implements RendezVousRemoteDataSource {
  final FirebaseFirestore firestore;
  final RendezVousLocalDataSource localDataSource;
  final NotificationRemoteDataSource notificationRemoteDataSource;

  RendezVousRemoteDataSourceImpl({
    required this.firestore,
    required this.localDataSource,
    required this.notificationRemoteDataSource,
  });

  @override
  Future<List<RendezVousModel>> getRendezVous({
    String? patientId,
    String? doctorId,
  }) async {
    if (patientId == null && doctorId == null) {
      throw ServerException('Soit patientId ou doctorId doit être fourni');
    }
    try {
      print(
        'RendezVousRemoteDataSource: Récupération des rendez-vous pour patientId=$patientId, doctorId=$doctorId',
      );

      Query<Map<String, dynamic>> query = firestore.collection('rendez_vous');
      if (patientId != null) {
        query = query.where('patientId', isEqualTo: patientId);
      }
      if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId);
      }

      final snapshot = await query.get();
      print(
        'RendezVousRemoteDataSource: ${snapshot.docs.length} rendez-vous trouvés',
      );

      final rendezVous =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Ensure the ID is set correctly
            print(
              'RendezVousRemoteDataSource: Traitement du rendez-vous ${doc.id}: statut=${data['status']}',
            );
            return RendezVousModel.fromJson(data);
          }).toList();

      await localDataSource.cacheRendezVous(rendezVous);
      return rendezVous;
    } on FirebaseException catch (e) {
      print('RendezVousRemoteDataSource: Erreur Firestore: ${e.message}');
      throw ServerException('Erreur de serveur: ${e.message}');
    } catch (e) {
      print('RendezVousRemoteDataSource: Erreur inattendue: $e');
      throw ServerException('Erreur inattendue: $e');
    }
  }

  @override
  Future<void> updateRendezVousStatus(
    String rendezVousId,
    String status,
    String patientId,
    String doctorId,
    String patientName,
    String doctorName,
    String recipientRole,
  ) async {
    try {
      // Get the current appointment data
      final appointmentDoc =
          await firestore.collection('rendez_vous').doc(rendezVousId).get();
      if (!appointmentDoc.exists) {
        throw ServerMessageException('Rendez-vous non trouvé');
      }

      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      DateTime startTime;

      // Parse startTime from the document
      if (appointmentData['startTime'] is Timestamp) {
        startTime = (appointmentData['startTime'] as Timestamp).toDate();
      } else if (appointmentData['startTime'] is String) {
        startTime = DateTime.parse(appointmentData['startTime'] as String);
      } else {
        throw ServerException('Format de date de début invalide dans le rendez-vous');
      }

      // Handle different status updates
      if (status == 'accepted') {
        // Get the doctor's appointment duration
        final appointmentDuration = await fetchDoctorAppointmentDuration(
          doctorId,
        );
        final endTime = startTime.add(Duration(minutes: appointmentDuration));

        await firestore.collection('rendez_vous').doc(rendezVousId).update({
          'status': status,
          'endTime': endTime.toIso8601String(),
        });

        // Create conversation if it doesn't exist (non-blocking)
        try {
          final existingConversation =
              await firestore
                  .collection('conversations')
                  .where('patientId', isEqualTo: patientId)
                  .where('doctorId', isEqualTo: doctorId)
                  .get();

          if (existingConversation.docs.isEmpty) {
            await firestore.collection('conversations').add({
              'patientId': patientId,
              'doctorId': doctorId,
              'patientName': patientName,
              'doctorName': doctorName,
              'lastMessage': 'Conversation démarrée pour le rendez-vous',
              'lastMessageType': 'text',
              'lastMessageTime': DateTime.now().toIso8601String(),
              'lastMessageSenderId': doctorId,
              'lastMessageReadBy': [doctorId],
            });
          }
        } catch (e) {
          print('Erreur lors de la création de la conversation: $e');
          // Don't fail the status update if conversation creation fails
        }

        // Notify patient about acceptance (non-blocking)
        try {
          await notificationRemoteDataSource.sendNotification(
            title: 'Rendez-vous accepté',
            body:
                'Dr. $doctorName a accepté votre rendez-vous du ${startTime.toLocal().toString().substring(0, 16)}.',
            senderId: doctorId,
            recipientId: patientId,
            type: NotificationType.appointmentAccepted,
            appointmentId: rendezVousId,
            recipientRole: 'patient',
            data: {
              'doctorName': doctorName,
              'startTime': startTime.toIso8601String(),
            },
          );
        } catch (e) {
          print('Erreur lors de l\'envoi de la notification d\'acceptation: $e');
          // Don't fail the status update if notification fails
        }
      } else if (status == 'rejected') {
        await firestore.collection('rendez_vous').doc(rendezVousId).update({
          'status': status,
        });

        // Notify patient about rejection (non-blocking)
        try {
          await notificationRemoteDataSource.sendNotification(
            title: 'Rendez-vous refusé',
            body:
                'Dr. $doctorName a refusé votre rendez-vous du ${startTime.toLocal().toString().substring(0, 16)}.',
            senderId: doctorId,
            recipientId: patientId,
            type: NotificationType.appointmentRejected,
            appointmentId: rendezVousId,
            recipientRole: 'patient',
            data: {
              'doctorName': doctorName,
              'startTime': startTime.toIso8601String(),
            },
          );
        } catch (e) {
          print('Erreur lors de l\'envoi de la notification de refus: $e');
          // Don't fail the status update if notification fails
        }
      } else if (status == 'canceled') {
        // Determine who is canceling (patient or doctor)
        final isPatientCanceling = recipientRole == 'patient';

        await firestore.collection('rendez_vous').doc(rendezVousId).update({
          'status': status,
        });

        // Send cancellation notifications (non-blocking)
        try {
          if (isPatientCanceling) {
            // Notify doctor about patient's cancellation
            await notificationRemoteDataSource.sendNotification(
              title: 'Rendez-vous annulé',
              body:
                  '$patientName a annulé le rendez-vous du ${startTime.toLocal().toString().substring(0, 16)}.',
              senderId: patientId,
              recipientId: doctorId,
              type: NotificationType.appointmentCanceled,
              appointmentId: rendezVousId,
              recipientRole: 'doctor',
              data: {
                'patientName': patientName,
                'startTime': startTime.toIso8601String(),
              },
            );
          } else {
            // Notify patient about doctor's cancellation
            await notificationRemoteDataSource.sendNotification(
              title: 'Rendez-vous annulé',
              body:
                  'Dr. $doctorName a annulé votre rendez-vous du ${startTime.toLocal().toString().substring(0, 16)}.',
              senderId: doctorId,
              recipientId: patientId,
              type: NotificationType.appointmentCanceled,
              appointmentId: rendezVousId,
              recipientRole: 'patient',
              data: {
                'doctorName': doctorName,
                'startTime': startTime.toIso8601String(),
              },
            );
          }
        } catch (e) {
          print('Erreur lors de l\'envoi de la notification d\'annulation: $e');
          // Don't fail the status update if notification fails
        }
      } else {
        // For other status updates
        await firestore.collection('rendez_vous').doc(rendezVousId).update({
          'status': status,
        });
      }

      print('Mise à jour réussie du rendez-vous $rendezVousId au statut $status');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw ServerMessageException('Rendez-vous non trouvé');
      }
      throw ServerException('Erreur de serveur: ${e.message}');
    } catch (e) {
      throw ServerException('Erreur inattendue: $e');
    }
  }

  // Helper method to fetch doctor's appointment duration
  Future<int> fetchDoctorAppointmentDuration(String? doctorId) async {
    if (doctorId == null) {
      return 30; // Default duration if no doctor is assigned yet
    }

    try {
      final doctorDoc =
          await firestore.collection('medecins').doc(doctorId).get();
      if (doctorDoc.exists) {
        final data = doctorDoc.data() as Map<String, dynamic>;
        return data['appointmentDuration'] as int? ?? 30;
      }
      return 30; // Default if doctor not found
    } catch (e) {
      print('Erreur lors de la récupération de la durée du rendez-vous: $e');
      return 30; // Default in case of error
    }
  }

  @override
  Future<void> createRendezVous(RendezVousModel rendezVous) async {
    try {
      final docRef = firestore.collection('rendez_vous').doc();

      // Calculate endTime based on doctor's appointmentDuration
      DateTime? endTime = rendezVous.endTime;

      // If endTime is not provided, calculate it based on doctor's appointment duration
      if (endTime == null && rendezVous.doctorId != null) {
        final appointmentDuration = await fetchDoctorAppointmentDuration(
          rendezVous.doctorId,
        );
        endTime = rendezVous.startTime.add(
          Duration(minutes: appointmentDuration),
        );
      }

      final rendezVousWithId = RendezVousModel(
        id: docRef.id,
        patientId: rendezVous.patientId,
        doctorId: rendezVous.doctorId,
        patientName: rendezVous.patientName,
        doctorName: rendezVous.doctorName,
        speciality: rendezVous.speciality,
        startTime: rendezVous.startTime,
        endTime: endTime,
        status: rendezVous.status,
      );
      await docRef.set(rendezVousWithId.toJson());

      // Send notification to the doctor (if assigned) or patient
      if (rendezVous.doctorId != null && rendezVous.doctorId!.isNotEmpty) {
        await notificationRemoteDataSource.sendNotification(
          title: 'Nouvelle demande de rendez-vous',
          body:
              '${rendezVous.patientName} a demandé un rendez-vous le ${rendezVous.startTime.toLocal().toString().substring(0, 16)}.',
          senderId: rendezVous.patientId!,
          recipientId: rendezVous.doctorId!,
          type: NotificationType.newAppointment,
          appointmentId: docRef.id,
          recipientRole: 'doctor',
          data: {
            'patientName': rendezVous.patientName,
            'startTime': rendezVous.startTime.toIso8601String(),
          },
        );
        print(
          'Notification envoyée pour le nouveau rendez-vous ${docRef.id} au médecin ${rendezVous.doctorId}',
        );
      } else {
        // Notify patient if no doctor is assigned yet
        await notificationRemoteDataSource.sendNotification(
          title: 'Rendez-vous créé',
          body:
              'Votre demande de rendez-vous pour ${rendezVous.speciality} le ${rendezVous.startTime.toLocal().toString().substring(0, 16)} a été créée.',
          senderId: rendezVous.patientId!,
          recipientId: rendezVous.patientId!,
          type: NotificationType.newAppointment,
          appointmentId: docRef.id,
          recipientRole: 'patient',
          data: {
            'patientName': rendezVous.patientName,
            'startTime': rendezVous.startTime.toIso8601String(),
            'speciality': rendezVous.speciality,
          },
        );
        print(
          'Notification envoyée pour le nouveau rendez-vous ${docRef.id} au patient ${rendezVous.patientId}',
        );
      }
    } on FirebaseException catch (e) {
      throw ServerException('Erreur de serveur: ${e.message}');
    } catch (e) {
      throw ServerException('Erreur inattendue: $e');
    }
  }

  @override
  Future<List<MedecinEntity>> getDoctorsBySpecialty(
    String specialty,
    DateTime startTime, {
    double? searchRadiusKm,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      print('Recherche de médecins avec spécialité: $specialty');
      print('Rayon de recherche: ${searchRadiusKm ?? "illimité"} km');
      print(
        'Localisation utilisateur: ${userLatitude ?? "inconnue"}, ${userLongitude ?? "inconnue"}',
      );

      final doctorSnapshot =
          await firestore
              .collection('medecins')
              .where('speciality', isEqualTo: specialty)
              .get();

      print(
        'Trouvé ${doctorSnapshot.docs.length} médecins avec spécialité $specialty',
      );

      final doctors =
          doctorSnapshot.docs
              .map((doc) => MedecinModel.fromJson(doc.data()).toEntity())
              .toList();

      final availableDoctors = <MedecinEntity>[];

      for (final doctor in doctors) {
        // Check location-based filtering if search radius and user location are provided
        if (searchRadiusKm != null &&
            userLatitude != null &&
            userLongitude != null) {
          double? doctorLatitude;
          double? doctorLongitude;

          // Handle both old format (separate lat/lng fields) and new GeoJSON format
          if (doctor.location != null) {
            if (doctor.location!.containsKey('coordinates') &&
                doctor.location!['coordinates'] is List &&
                (doctor.location!['coordinates'] as List).length >= 2) {
              // New GeoJSON format: [longitude, latitude]
              final coordinates = doctor.location!['coordinates'] as List;
              doctorLongitude = (coordinates[0] as num).toDouble();
              doctorLatitude = (coordinates[1] as num).toDouble();
            } else if (doctor.location!.containsKey('latitude') &&
                doctor.location!.containsKey('longitude')) {
              // Old format: separate latitude and longitude fields
              doctorLatitude =
                  (doctor.location!['latitude'] as num?)?.toDouble();
              doctorLongitude =
                  (doctor.location!['longitude'] as num?)?.toDouble();
            }
          }

          // Skip doctors without valid location data
          if (doctorLatitude == null || doctorLongitude == null) {
            print('Médecin ${doctor.name} ignoré - données de localisation invalides');
            continue;
          }

          // Calculate distance using LocationService
          final distance = LocationService.getDistanceBetween(
            userLatitude,
            userLongitude,
            doctorLatitude,
            doctorLongitude,
          );

          print(
            'Distance du médecin ${doctor.name}: ${distance.toStringAsFixed(2)} km',
          );

          // Skip doctors outside the search radius
          if (distance > searchRadiusKm) {
            print('Médecin ${doctor.name} ignoré - en dehors du rayon de recherche');
            continue;
          }
        }

        // Check for appointment conflicts with improved status checking
        final rendezVousSnapshot =
            await firestore
                .collection('rendez_vous')
                .where('doctorId', isEqualTo: doctor.id)
                .where('startTime', isEqualTo: startTime.toIso8601String())
                .where(
                  'status',
                  whereIn: ['accepted', 'pending'],
                ) // Check both accepted and pending appointments
                .get();

        if (rendezVousSnapshot.docs.isEmpty) {
          print(
            'Médecin ${doctor.name} est disponible à ${startTime.toString()}',
          );
          availableDoctors.add(doctor);
        } else {
          print(
            'Médecin ${doctor.name} a un conflit à ${startTime.toString()} - ${rendezVousSnapshot.docs.length} rendez-vous',
          );
        }
      }

      print(
        'Trouvé ${availableDoctors.length} médecins disponibles selon les critères',
      );
      return availableDoctors;
    } on FirebaseException catch (e) {
      throw ServerException('Erreur de serveur: ${e.message}');
    } catch (e) {
      throw ServerException('Erreur inattendue: $e');
    }
  }

  @override
  Future<void> assignDoctorToRendezVous(
    String rendezVousId,
    String doctorId,
    String doctorName,
  ) async {
    try {
      // Get the current appointment data to access the startTime and patient info
      final appointmentDoc =
          await firestore.collection('rendez_vous').doc(rendezVousId).get();
      if (!appointmentDoc.exists) {
        throw ServerMessageException('Rendez-vous non trouvé');
      }

      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      DateTime startTime;

      // Parse startTime from the document
      if (appointmentData['startTime'] is Timestamp) {
        startTime = (appointmentData['startTime'] as Timestamp).toDate();
      } else if (appointmentData['startTime'] is String) {
        startTime = DateTime.parse(appointmentData['startTime'] as String);
      } else {
        throw ServerException('Format de date de début invalide dans le rendez-vous');
      }

      // Get the doctor's appointment duration
      final appointmentDuration = await fetchDoctorAppointmentDuration(
        doctorId,
      );

      // Calculate endTime based on startTime and appointmentDuration
      final endTime = startTime.add(Duration(minutes: appointmentDuration));

      // Update the appointment with doctor info and calculated endTime
      await firestore.collection('rendez_vous').doc(rendezVousId).update({
        'doctorId': doctorId,
        'doctorName': doctorName,
        'status': 'pending',
        'endTime': endTime.toIso8601String(),
      });

      // Send notifications to both doctor and patient
      final patientId = appointmentData['patientId'] as String;
      final patientName = appointmentData['patientName'] as String;

      // Notify doctor
      await notificationRemoteDataSource.sendNotification(
        title: 'Nouveau rendez-vous assigné',
        body:
            'Un rendez-vous avec $patientName vous a été assigné le ${startTime.toLocal().toString().substring(0, 16)}.',
        senderId: patientId,
        recipientId: doctorId,
        type: NotificationType.newAppointment,
        appointmentId: rendezVousId,
        recipientRole: 'doctor',
        data: {
          'patientName': patientName,
          'startTime': startTime.toIso8601String(),
        },
      );
      print(
        'Notification envoyée pour le rendez-vous assigné $rendezVousId au médecin $doctorId',
      );

      // Notify patient
      await notificationRemoteDataSource.sendNotification(
        title: 'Médecin assigné au rendez-vous',
        body:
            'Dr. $doctorName a été assigné à votre rendez-vous du ${startTime.toLocal().toString().substring(0, 16)}.',
        senderId: doctorId,
        recipientId: patientId,
        type: NotificationType.newAppointment,
        appointmentId: rendezVousId,
        recipientRole: 'patient',
        data: {
          'doctorName': doctorName,
          'startTime': startTime.toIso8601String(),
        },
      );
      print(
        'Notification envoyée pour le rendez-vous assigné $rendezVousId au patient $patientId',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw ServerMessageException('Rendez-vous non trouvé');
      }
      throw ServerException('Erreur de serveur: ${e.message}');
    } catch (e) {
      throw ServerException('Erreur inattendue: $e');
    }
  }
}
