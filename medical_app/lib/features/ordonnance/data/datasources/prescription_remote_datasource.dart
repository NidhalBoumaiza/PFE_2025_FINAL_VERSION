import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/ordonnance/domain/entities/prescription_entity.dart';
import 'package:medical_app/features/ordonnance/data/models/prescription_model.dart';
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';

abstract class PrescriptionRemoteDataSource {
  Future<PrescriptionModel> createPrescription(PrescriptionEntity prescription);
  Future<PrescriptionModel> editPrescription(PrescriptionEntity prescription);
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId);
  Future<List<PrescriptionModel>> getDoctorPrescriptions(String doctorId);
  Future<PrescriptionModel> getPrescriptionById(String prescriptionId);
  Future<PrescriptionModel?> getPrescriptionByAppointmentId(String appointmentId);
  Future<void> updatePrescription(PrescriptionEntity prescription);
}

class PrescriptionRemoteDataSourceImpl implements PrescriptionRemoteDataSource {
  final FirebaseFirestore firestore;
  final NotificationRemoteDataSource notificationRemoteDataSource;

  PrescriptionRemoteDataSourceImpl({
    required this.firestore,
    required this.notificationRemoteDataSource,
  });

  Future<void> _sendPrescriptionNotification({
    required String action,
    required PrescriptionEntity prescription,
    String? additionalMessage,
  }) async {
    try {
      // Get doctor details
      final doctorDoc = await firestore.collection('medecins').doc(prescription.doctorId).get();
      final doctorName = doctorDoc.get('name') ?? 'Your doctor';

      // Get patient details
      final patientDoc = await firestore.collection('patients').doc(prescription.patientId).get();
      final patientName = patientDoc.get('name') ?? 'Patient';

      // Determine notification content based on action
      String title;
      String body;
      NotificationType type;

      switch (action) {
        case 'created':
          title = 'New Prescription';
          body = 'Dr. $doctorName has created a new prescription for you.';
          type = NotificationType.newPrescription;
          break;
        case 'updated':
          title = 'Prescription Updated';
          body = 'Dr. $doctorName has updated your prescription${additionalMessage != null ? ': $additionalMessage' : ''}';
          type = NotificationType.prescriptionUpdated;
          break;
        case 'refilled':
          title = 'Prescription Refilled';
          body = 'Dr. $doctorName has refilled your prescription.';
          type = NotificationType.prescriptionRefilled;
          break;
        case 'canceled':
          title = 'Prescription Canceled';
          body = 'Dr. $doctorName has canceled your prescription.';
          type = NotificationType.prescriptionCanceled;
          break;
        default:
          title = 'Prescription Update';
          body = 'Your prescription has been updated by Dr. $doctorName';
          type = NotificationType.prescriptionUpdated;
      }

      // Send notification
      await notificationRemoteDataSource.sendNotification(
        title: title,
        body: body,
        senderId: prescription.doctorId,
        recipientId: prescription.patientId,
        type: type,
        prescriptionId: prescription.id,
        appointmentId: prescription.appointmentId,
        data: {
          'doctorName': doctorName,
          'patientName': patientName,
          'action': action,
          if (additionalMessage != null) 'additionalMessage': additionalMessage,
        },
        recipientRole: 'patient',
      );

      print('Sent $action notification for prescription ${prescription.id}');
    } catch (e) {
      print('Error sending $action notification: $e');
      // Don't throw error to prevent blocking the main operation
    }
  }

  @override
  Future<PrescriptionModel> createPrescription(PrescriptionEntity prescription) async {
    try {
      final prescriptionModel = PrescriptionModel.fromEntity(prescription);

      // Create prescription
      await firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .set(prescriptionModel.toJson());

      // Update appointment status
      await firestore.collection('rendez_vous').doc(prescription.appointmentId).update({
        'status': 'completed',
        'hasPrescription': true,
      });

      // Send notification
      await _sendPrescriptionNotification(
        action: 'created',
        prescription: prescription,
      );

      return prescriptionModel;
    } catch (e) {
      throw ServerException('Failed to create prescription: $e');
    }
  }

  @override
  Future<PrescriptionModel> editPrescription(PrescriptionEntity prescription) async {
    try {
      // Check if prescription exists and can be edited
      final doc = await firestore.collection('prescriptions').doc(prescription.id).get();

      if (!doc.exists) {
        throw ServerException('Prescription not found');
      }

      final existingPrescription = PrescriptionModel.fromJson(doc.data()!);
      final now = DateTime.now();
      final difference = now.difference(existingPrescription.date);

      if (difference.inHours >= 12) {
        throw ServerException('Cannot edit prescription after 12 hours of creation');
      }

      // Update prescription
      final prescriptionModel = PrescriptionModel.fromEntity(prescription);
      await firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .update(prescriptionModel.toJson());

      // Send notification with edit details
      await _sendPrescriptionNotification(
        action: 'updated',
        prescription: prescription,
        additionalMessage: 'Changes made to your medication',
      );

      return prescriptionModel;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to edit prescription: $e');
    }
  }

  @override
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
    try {
      final querySnapshot = await firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PrescriptionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch patient prescriptions: $e');
    }
  }

  @override
  Future<List<PrescriptionModel>> getDoctorPrescriptions(String doctorId) async {
    try {
      final querySnapshot = await firestore
          .collection('prescriptions')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PrescriptionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch doctor prescriptions: $e');
    }
  }

  @override
  Future<PrescriptionModel> getPrescriptionById(String prescriptionId) async {
    try {
      final docSnapshot = await firestore
          .collection('prescriptions')
          .doc(prescriptionId)
          .get();

      if (!docSnapshot.exists) {
        throw ServerException('Prescription not found');
      }

      return PrescriptionModel.fromJson(docSnapshot.data()!);
    } catch (e) {
      if (e is ServerException) {
        throw e;
      }
      throw ServerException('Failed to fetch prescription: $e');
    }
  }

  @override
  Future<PrescriptionModel?> getPrescriptionByAppointmentId(String appointmentId) async {
    try {
      final querySnapshot = await firestore
          .collection('prescriptions')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return PrescriptionModel.fromJson(querySnapshot.docs.first.data());
    } catch (e) {
      throw ServerException('Failed to fetch prescription by appointment: $e');
    }
  }

  @override
  Future<void> updatePrescription(PrescriptionEntity prescription) async {
    try {
      final prescriptionModel = PrescriptionModel.fromEntity(prescription);

      // Update prescription
      await firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .update(prescriptionModel.toJson());

      // Send notification
      await _sendPrescriptionNotification(
        action: 'updated',
        prescription: prescription,
      );
    } catch (e) {
      throw ServerException('Failed to update prescription: $e');
    }
  }



}