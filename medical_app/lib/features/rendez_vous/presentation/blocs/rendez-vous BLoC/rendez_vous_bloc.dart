import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/status_appointment.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/create_rendez_vous_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/fetch_doctors_by_specialty_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/fetch_rendez_vous_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/update_rendez_vous_status_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/assign_doctor_to_rendez_vous_use_case.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

part 'rendez_vous_event.dart';
part 'rendez_vous_state.dart';

class RendezVousBloc extends Bloc<RendezVousEvent, RendezVousState> {
  final FetchRendezVousUseCase fetchRendezVousUseCase;
  final UpdateRendezVousStatusUseCase updateRendezVousStatusUseCase;
  final CreateRendezVousUseCase createRendezVousUseCase;
  final FetchDoctorsBySpecialtyUseCase fetchDoctorsBySpecialtyUseCase;
  final AssignDoctorToRendezVousUseCase assignDoctorToRendezVousUseCase;
  final NotificationBloc? notificationBloc;

  RendezVousBloc({
    required this.fetchRendezVousUseCase,
    required this.updateRendezVousStatusUseCase,
    required this.createRendezVousUseCase,
    required this.fetchDoctorsBySpecialtyUseCase,
    required this.assignDoctorToRendezVousUseCase,
    this.notificationBloc,
  }) : super(RendezVousInitial()) {
    on<FetchRendezVous>(_onFetchRendezVous);
    on<UpdateRendezVousStatus>(_onUpdateRendezVousStatus);
    on<CreateRendezVous>(_onCreateRendezVous);
    on<FetchDoctorsBySpecialty>(_onFetchDoctorsBySpecialty);
    on<AssignDoctorToRendezVous>(_onAssignDoctorToRendezVous);
    on<CheckAndUpdatePastAppointments>(_onCheckAndUpdatePastAppointments);
  }

  Future<void> _onFetchRendezVous(
      FetchRendezVous event,
      Emitter<RendezVousState> emit,
      ) async {
    emit(RendezVousLoading());
    
    if (event.appointmentId != null) {
      try {
        // Fetch a specific appointment by ID
        final documentSnapshot =
            await FirebaseFirestore.instance
            .collection('rendez_vous')
            .doc(event.appointmentId)
            .get();
        
        if (documentSnapshot.exists) {
          final data = documentSnapshot.data() as Map<String, dynamic>;
          final appointment = RendezVousEntity(
            id: documentSnapshot.id,
            patientId: data['patientId'] as String?,
            patientName: data['patientName'] as String?,
            doctorId: data['doctorId'] as String?,
            doctorName: data['doctorName'] as String?,
            startTime:
                data['startTime'] is Timestamp
                ? (data['startTime'] as Timestamp).toDate()
                : DateTime.parse(data['startTime'] as String),
            endTime:
                data['endTime'] is Timestamp
                ? (data['endTime'] as Timestamp).toDate()
                : data['endTime'] != null 
                    ? DateTime.parse(data['endTime'] as String)
                    : null,
            status: data['status'] as String,
            speciality: data['speciality'] as String?,
          );
          
          emit(RendezVousLoaded([appointment]));
        } else {
          emit(RendezVousError('Appointment not found'));
        }
      } catch (e) {
        emit(RendezVousError('Error fetching appointment: $e'));
      }
      return;
    }
    
    // Original code for fetching multiple appointments
    final failureOrRendezVous = await fetchRendezVousUseCase(
      patientId: event.patientId,
      doctorId: event.doctorId,
    );
    emit(
      failureOrRendezVous.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (rendezVous) => RendezVousLoaded(rendezVous),
      ),
    );
  }

  Future<void> _onUpdateRendezVousStatus(
      UpdateRendezVousStatus event,
      Emitter<RendezVousState> emit,
      ) async {
    try {
      emit(UpdatingRendezVousState());
      
      // Get the current rendez-vous to get patient and medecin data
      final rendezVous = await fetchRendezVousUseCase(
        patientId: event.patientId,
        doctorId: event.doctorId,
      );
      
      // Update the status
      final failureOrUnit = await updateRendezVousStatusUseCase(
        rendezVousId: event.rendezVousId,
        status: event.status,
        patientId: event.patientId,
        doctorId: event.doctorId,
        patientName: event.patientName,
        doctorName: event.doctorName,
      );
      
      // Send notification based on status change
      if (rendezVous.isRight()) {
        rendezVous.fold((l) => null, (appointment) {
          if (event.status == 'accepted') {
            _sendAppointmentAcceptedNotification(
              appointment.firstWhere(
              (a) => a.id == event.rendezVousId,
                orElse:
                    () => RendezVousEntity(
                startTime: DateTime.now(),
                      status: 'not_found',
                    ),
              ),
            );
          } else if (event.status == 'rejected') {
            _sendAppointmentRejectedNotification(
              appointment.firstWhere(
              (a) => a.id == event.rendezVousId,
                orElse:
                    () => RendezVousEntity(
                startTime: DateTime.now(),
                      status: 'not_found',
                    ),
              ),
            );
          }
        });
      }
      
      emit(
        failureOrUnit.fold(
            (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (_) => RendezVousStatusUpdatedState(
            id: event.rendezVousId,
            status: event.status,
          ),
        ),
      );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  Future<void> _onCreateRendezVous(
      CreateRendezVous event,
      Emitter<RendezVousState> emit,
      ) async {
    try {
      emit(AddingRendezVousState());
      final result = await createRendezVousUseCase(event.rendezVous);
      
      result.fold(
        (failure) => emit(RendezVousErrorState(message: failure.message)),
        (_) {
          // Send notification to doctor about new appointment
          _sendNewAppointmentNotification(event.rendezVous);

          // Emit RendezVousCreated state for navigation in UI
          emit(RendezVousCreated());
        },
      );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  Future<void> _onFetchDoctorsBySpecialty(
      FetchDoctorsBySpecialty event,
      Emitter<RendezVousState> emit,
      ) async {
    emit(RendezVousLoading());
    final failureOrDoctors = await fetchDoctorsBySpecialtyUseCase(
      event.specialty,
      event.startTime,
    );
    emit(
      failureOrDoctors.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (doctors) => DoctorsLoaded(doctors),
      ),
    );
  }

  Future<void> _onAssignDoctorToRendezVous(
      AssignDoctorToRendezVous event,
      Emitter<RendezVousState> emit,
      ) async {
    emit(RendezVousLoading());
    final failureOrUnit = await assignDoctorToRendezVousUseCase(
      event.rendezVousId,
      event.doctorId,
      event.doctorName,
    );
    emit(
      failureOrUnit.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (_) => RendezVousDoctorAssigned(),
      ),
    );
  }

  Future<void> _onCheckAndUpdatePastAppointments(
    CheckAndUpdatePastAppointments event,
    Emitter<RendezVousState> emit,
  ) async {
    print(
      'Starting CheckAndUpdatePastAppointments for user: ${event.userId}, role: ${event.userRole}',
    );
    try {
      // Get current time
      final now = DateTime.now();
      print('Current time: ${now.toString()}');
      
      // Reference to Firestore
      final firestore = FirebaseFirestore.instance;
      
      // Create a query based on the user's role
      Query query;
      if (event.userRole == 'medecin') {
        query = firestore
            .collection('rendez_vous')
            .where('doctorId', isEqualTo: event.userId)
            .where('status', isEqualTo: 'accepted');
      } else {
        query = firestore
            .collection('rendez_vous')
            .where('patientId', isEqualTo: event.userId)
            .where('status', isEqualTo: 'accepted');
      }
      
      // Execute the query
      final querySnapshot = await query.get();
      print('Found ${querySnapshot.docs.length} accepted appointments');
      
      // Process each document
      int updatedCount = 0;
      for (var doc in querySnapshot.docs) {
        // Parse the appointment start time
        final data = doc.data() as Map<String, dynamic>;
        DateTime startTime;
        if (data['startTime'] is Timestamp) {
          startTime = (data['startTime'] as Timestamp).toDate();
        } else {
          startTime = DateTime.parse(data['startTime'] as String);
        }
        
        print(
          'Appointment ${doc.id}: startTime=${startTime.toString()}, isBefore=${startTime.isBefore(now)}',
        );
        
        // If the appointment has passed, update it to completed
        if (startTime.isBefore(now)) {
          // Get additional data for notification
          final patientId = data['patientId'] as String?;
          final patientName = data['patientName'] as String?;
          final doctorId = data['doctorId'] as String?;
          final doctorName = data['doctorName'] as String?;
          
          if (patientId != null &&
              patientName != null &&
              doctorId != null &&
              doctorName != null) {
            print('Updating appointment ${doc.id} to completed');
            
            // Update status to completed
            try {
              await firestore.collection('rendez_vous').doc(doc.id).update({
                'status': 'completed',
              });
              updatedCount++;
            } catch (updateError) {
              print('Error updating appointment ${doc.id}: $updateError');
            }
          }
        }
      }
      
      print('Updated $updatedCount appointments to completed');
      
      // Emit state to indicate updates are complete
      emit(PastAppointmentsChecked(updatedCount: updatedCount));
      
      // After processing all appointments, fetch updated list
      if (updatedCount > 0) {
        print('Fetching updated appointments for ${event.userRole}');
        if (event.userRole == 'medecin') {
          add(FetchRendezVous(doctorId: event.userId));
        } else {
          add(FetchRendezVous(patientId: event.userId));
        }
      }
    } catch (e) {
      print('Error checking past appointments: $e');
      // We don't emit an error state here to avoid interrupting the user experience
      // but we log the error for debugging purposes
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Une erreur serveur s\'est produite';
      case ServerMessageFailure:
        final message = (failure as ServerMessageFailure).message;
        return message == 'Rendezvous not found'
            ? 'Consultation non trouvée'
            : message;
      case OfflineFailure:
        return 'Pas de connexion internet';
      case EmptyCacheFailure:
        return 'Aucune donnée en cache disponible';
      default:
        return 'Une erreur inattendue s\'est produite';
    }
  }

  // Helper methods to send notifications
  void _sendNewAppointmentNotification(RendezVousEntity rendezVous) {
    if (notificationBloc != null &&
        rendezVous.patientId != null &&
        rendezVous.doctorId != null) {
      // Format date for better readability
      String formattedDate = rendezVous.startTime.toString().substring(0, 10);
      String formattedTime = _formatTime(rendezVous.startTime);

      // Create notification data
      Map<String, dynamic> notificationData = {
        'patientName': rendezVous.patientName ?? 'Unknown',
        'doctorName': rendezVous.doctorName ?? 'Unknown',
        'appointmentDate': formattedDate,
        'appointmentTime': formattedTime,
        'speciality': rendezVous.speciality ?? '',
        'type': 'newAppointment',
        'senderId': rendezVous.patientId!,
        'recipientId': rendezVous.doctorId!,
        'appointmentId': rendezVous.id,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      // 1. Send through NotificationBloc (primary method)
      notificationBloc!.add(
        SendNotificationEvent(
          title: 'Nouveau rendez-vous',
          body:
              '${rendezVous.patientName ?? "Un patient"} a demandé un rendez-vous pour le $formattedDate à $formattedTime',
          senderId: rendezVous.patientId!,
          recipientId: rendezVous.doctorId!,
          type: NotificationType.newAppointment,
          appointmentId: rendezVous.id,
          data: notificationData,
        ),
      );

      // 2. Direct method attempt using Firebase (backup)
      try {
        _directlySendNotification(
          doctorId: rendezVous.doctorId!,
          title: 'Nouveau rendez-vous',
          body:
              '${rendezVous.patientName ?? "Un patient"} a demandé un rendez-vous pour le $formattedDate à $formattedTime',
          data: notificationData,
        );
      } catch (e) {
        print('Error in direct notification sending: $e');
      }

      print(
        'Sent notification for new appointment to doctor ${rendezVous.doctorId}',
      );
    } else {
      print(
        'Could not send notification: ${notificationBloc == null ? "NotificationBloc is null" : "Missing patient or doctor ID"}',
      );
    }
  }

  // Helper method for direct notification sending
  Future<void> _directlySendNotification({
    required String doctorId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Query Firestore to get doctor's FCM token - check in multiple collections
      final firestore = FirebaseFirestore.instance;
      String? fcmToken;
      
      // Try medecins collection first
      final doctorDoc = await firestore.collection('medecins').doc(doctorId).get();
      if (doctorDoc.exists && doctorDoc.data()?['fcmToken'] != null) {
        fcmToken = doctorDoc.data()?['fcmToken'] as String?;
      }
      
      // If not found, try users collection
      if (fcmToken == null || fcmToken.isEmpty) {
        final userDoc = await firestore.collection('users').doc(doctorId).get();
        if (userDoc.exists && userDoc.data()?['fcmToken'] != null) {
          fcmToken = userDoc.data()?['fcmToken'] as String?;
        }
      }
      
      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Send the notification directly to FCM via server
        await _sendNotificationViaServer(
          token: fcmToken,
          title: title,
          body: body,
          data: data,
        );
        print('Sent direct notification to FCM token: $fcmToken');
      } else {
        print('Could not find FCM token for doctor: $doctorId');
      }
    } catch (e) {
      print('Error in _directlySendNotification: $e');
    }
  }
  
  // Helper method to send notification via server
  Future<void> _sendNotificationViaServer({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Use both localhost (10.0.2.2) for emulator and the IP address for real devices
      const String baseUrl = 'http://10.0.2.2:3000/api/v1'; 
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully via server');
      } else {
        print('Failed to send notification via server: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification via server: $e');
      
      // Fall back to saving directly to Firestore
      try {
        await FirebaseFirestore.instance.collection('fcm_requests').add({
          'token': token,
          'payload': {
            'notification': {'title': title, 'body': body},
            'data': data,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Saved notification request to Firestore as fallback');
      } catch (e) {
        print('Error saving notification to Firestore: $e');
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _sendAppointmentAcceptedNotification(RendezVousEntity rendezVous) {
    if (notificationBloc != null &&
        rendezVous.patientId != null &&
        rendezVous.doctorId != null) {
      notificationBloc!.add(
        SendNotificationEvent(
          title: 'Appointment Accepted',
          body:
              'Dr. ${rendezVous.doctorName ?? "Unknown"} has accepted your appointment for ${rendezVous.startTime.toString().substring(0, 10)} at ${_formatTime(rendezVous.startTime)}',
          senderId: rendezVous.doctorId!,
          recipientId: rendezVous.patientId!,
          type: NotificationType.appointmentAccepted,
          appointmentId: rendezVous.id,
          data: {
            'doctorName': rendezVous.doctorName ?? 'Unknown',
            'patientName': rendezVous.patientName ?? 'Unknown',
            'appointmentDate': rendezVous.startTime.toString().substring(0, 10),
            'appointmentTime': _formatTime(rendezVous.startTime),
          },
        ),
      );
    }
  }

  void _sendAppointmentRejectedNotification(RendezVousEntity rendezVous) {
    if (notificationBloc != null &&
        rendezVous.patientId != null &&
        rendezVous.doctorId != null) {
      notificationBloc!.add(
        SendNotificationEvent(
          title: 'Appointment Rejected',
          body:
              'Dr. ${rendezVous.doctorName ?? "Unknown"} has rejected your appointment for ${rendezVous.startTime.toString().substring(0, 10)} at ${_formatTime(rendezVous.startTime)}',
          senderId: rendezVous.doctorId!,
          recipientId: rendezVous.patientId!,
          type: NotificationType.appointmentRejected,
          appointmentId: rendezVous.id,
          data: {
            'doctorName': rendezVous.doctorName ?? 'Unknown',
            'patientName': rendezVous.patientName ?? 'Unknown',
            'appointmentDate': rendezVous.startTime.toString().substring(0, 10),
            'appointmentTime': _formatTime(rendezVous.startTime),
          },
        ),
      );
    }
  }
}
