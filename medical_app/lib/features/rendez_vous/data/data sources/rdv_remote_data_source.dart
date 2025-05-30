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
      throw ServerException('Either patientId or doctorId must be provided');
    }
    try {
      print(
        'RendezVousRemoteDataSource: Fetching appointments for patientId=$patientId, doctorId=$doctorId',
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
        'RendezVousRemoteDataSource: Found ${snapshot.docs.length} appointments',
      );

      final rendezVous =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Ensure the ID is set correctly
            print(
              'RendezVousRemoteDataSource: Processing appointment ${doc.id}: status=${data['status']}',
            );
            return RendezVousModel.fromJson(data);
          }).toList();

      await localDataSource.cacheRendezVous(rendezVous);
      return rendezVous;
    } on FirebaseException catch (e) {
      print('RendezVousRemoteDataSource: Firestore error: ${e.message}');
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      print('RendezVousRemoteDataSource: Unexpected error: $e');
      throw ServerException('Unexpected error: $e');
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
        throw ServerMessageException('Rendezvous not found');
      }

      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      DateTime startTime;

      // Parse startTime from the document
      if (appointmentData['startTime'] is Timestamp) {
        startTime = (appointmentData['startTime'] as Timestamp).toDate();
      } else if (appointmentData['startTime'] is String) {
        startTime = DateTime.parse(appointmentData['startTime'] as String);
      } else {
        throw ServerException('Invalid startTime format in appointment');
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
              'lastMessage': 'Conversation started for rendez-vous',
              'lastMessageType': 'text',
              'lastMessageTime': DateTime.now().toIso8601String(),
              'lastMessageSenderId': doctorId,
              'lastMessageReadBy': [doctorId],
            });
          }
        } catch (e) {
          print('Error creating conversation: $e');
          // Don't fail the status update if conversation creation fails
        }

        // Notify patient about acceptance (non-blocking)
        try {
          await notificationRemoteDataSource.sendNotification(
            title: 'Appointment Accepted',
            body:
                'Dr. $doctorName has accepted your appointment on ${startTime.toLocal().toString().substring(0, 16)}.',
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
          print('Error sending acceptance notification: $e');
          // Don't fail the status update if notification fails
        }
      } else if (status == 'rejected') {
        await firestore.collection('rendez_vous').doc(rendezVousId).update({
          'status': status,
        });

        // Notify patient about rejection (non-blocking)
        try {
          await notificationRemoteDataSource.sendNotification(
            title: 'Appointment Rejected',
            body:
                'Dr. $doctorName has rejected your appointment on ${startTime.toLocal().toString().substring(0, 16)}.',
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
          print('Error sending rejection notification: $e');
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
              title: 'Appointment Canceled',
              body:
                  '$patientName has canceled the appointment on ${startTime.toLocal().toString().substring(0, 16)}.',
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
              title: 'Appointment Canceled',
              body:
                  'Dr. $doctorName has canceled your appointment on ${startTime.toLocal().toString().substring(0, 16)}.',
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
          print('Error sending cancellation notification: $e');
          // Don't fail the status update if notification fails
        }
      } else {
        // For other status updates
        await firestore.collection('rendez_vous').doc(rendezVousId).update({
          'status': status,
        });
      }

      print('Successfully updated appointment $rendezVousId to status $status');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw ServerMessageException('Rendezvous not found');
      }
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
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
      print('Error fetching doctor appointment duration: $e');
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
          title: 'New Appointment Request',
          body:
              '${rendezVous.patientName} has requested an appointment on ${rendezVous.startTime.toLocal().toString().substring(0, 16)}.',
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
          'Sent notification for new appointment ${docRef.id} to doctor ${rendezVous.doctorId}',
        );
      } else {
        // Notify patient if no doctor is assigned yet
        await notificationRemoteDataSource.sendNotification(
          title: 'Appointment Created',
          body:
              'Your appointment request for ${rendezVous.speciality} on ${rendezVous.startTime.toLocal().toString().substring(0, 16)} has been created.',
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
          'Sent notification for new appointment ${docRef.id} to patient ${rendezVous.patientId}',
        );
      }
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
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
      print('Searching for doctors with specialty: $specialty');
      print('Search radius: ${searchRadiusKm ?? "unlimited"} km');
      print(
        'User location: ${userLatitude ?? "unknown"}, ${userLongitude ?? "unknown"}',
      );

      final doctorSnapshot =
          await firestore
              .collection('medecins')
              .where('speciality', isEqualTo: specialty)
              .get();

      print(
        'Found ${doctorSnapshot.docs.length} doctors with specialty $specialty',
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
            print('Skipping doctor ${doctor.name} - no valid location data');
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
            'Doctor ${doctor.name} distance: ${distance.toStringAsFixed(2)} km',
          );

          // Skip doctors outside the search radius
          if (distance > searchRadiusKm) {
            print('Skipping doctor ${doctor.name} - outside search radius');
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
            'Doctor ${doctor.name} is available at ${startTime.toString()}',
          );
          availableDoctors.add(doctor);
        } else {
          print(
            'Doctor ${doctor.name} has conflict at ${startTime.toString()} - ${rendezVousSnapshot.docs.length} appointments',
          );
        }
      }

      print(
        'Found ${availableDoctors.length} available doctors within criteria',
      );
      return availableDoctors;
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
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
        throw ServerMessageException('Rendezvous not found');
      }

      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      DateTime startTime;

      // Parse startTime from the document
      if (appointmentData['startTime'] is Timestamp) {
        startTime = (appointmentData['startTime'] as Timestamp).toDate();
      } else if (appointmentData['startTime'] is String) {
        startTime = DateTime.parse(appointmentData['startTime'] as String);
      } else {
        throw ServerException('Invalid startTime format in appointment');
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
        title: 'New Appointment Assigned',
        body:
            'You have been assigned an appointment with $patientName on ${startTime.toLocal().toString().substring(0, 16)}.',
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
        'Sent notification for assigned appointment $rendezVousId to doctor $doctorId',
      );

      // Notify patient
      await notificationRemoteDataSource.sendNotification(
        title: 'Doctor Assigned to Appointment',
        body:
            'Dr. $doctorName has been assigned to your appointment on ${startTime.toLocal().toString().substring(0, 16)}.',
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
        'Sent notification for assigned appointment $rendezVousId to patient $patientId',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw ServerMessageException('Rendezvous not found');
      }
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
}
