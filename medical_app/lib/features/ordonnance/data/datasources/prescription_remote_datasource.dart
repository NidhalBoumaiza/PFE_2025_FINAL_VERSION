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

  @override
  Future<PrescriptionModel> createPrescription(PrescriptionEntity prescription) async {
    try {
      final prescriptionModel = PrescriptionModel.fromEntity(prescription);
      await firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .set(prescriptionModel.toJson());

      // Update the appointment status to completed
      await firestore.collection('rendez_vous').doc(prescription.appointmentId).update({
        'status': 'completed',
      });

      // Send notification to the patient
      final doctorDoc = await firestore.collection('medecins').doc(prescription.doctorId).get();
      final doctorName = doctorDoc.exists ? doctorDoc.data() != null?['name'] ?? 'Doctor' : 'Doctor' : 'Doctor';
      await notificationRemoteDataSource.sendNotification(
        title: 'New Prescription',
        body: 'Dr. $doctorName has created a new prescription for you.',
        senderId: prescription.doctorId,
        recipientId: prescription.patientId,
        type: NotificationType.newPrescription,
        prescriptionId: prescription.id,
        appointmentId: prescription.appointmentId,
        data: {
          'doctorName': doctorName,
        },
        recipientRole: 'patient',
      );
      print('Sent notification for new prescription ${prescription.id} to patient ${prescription.patientId}');

      return prescriptionModel;
    } catch (e) {
      throw ServerException('Failed to create prescription: $e');
    }
  }

  @override
  Future<PrescriptionModel> editPrescription(PrescriptionEntity prescription) async {
    try {
      // Check if the prescription can be edited (12-hour window)
      final doc = await firestore.collection('prescriptions').doc(prescription.id).get();

      if (!doc.exists) {
        throw ServerException('Prescription not found');
      }

      final existingPrescription = PrescriptionModel.fromJson(doc.data() as Map<String, dynamic>);

      // Check the edit time window
      final now = DateTime.now();
      final difference = now.difference(existingPrescription.date);

      if (difference.inHours >= 12) {
        throw ServerException(
            'Cannot edit prescription after 12 hours of creation'
        );
      }

      final prescriptionModel = PrescriptionModel.fromEntity(prescription);
      await firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .update(prescriptionModel.toJson());

      // Send notification to the patient
      final doctorDoc = await firestore.collection('medecins').doc(prescription.doctorId).get();
      final doctorName = doctorDoc.exists ? doctorDoc.data() != null?['name'] ?? 'Doctor' : 'Doctor' : 'Doctor';
      await notificationRemoteDataSource.sendNotification(
        title: 'Prescription Updated',
        body: 'Dr. $doctorName has updated your prescription.',
        senderId: prescription.doctorId,
        recipientId: prescription.patientId,
        type: NotificationType.prescriptionUpdated,
        prescriptionId: prescription.id,
        appointmentId: prescription.appointmentId,
        data: {
          'doctorName': doctorName,
        },
        recipientRole: 'patient',
      );
      print('Sent notification for edited prescription ${prescription.id} to patient ${prescription.patientId}');

      return prescriptionModel;
    } catch (e) {
      if (e is ServerException) {
        throw e;
      }
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
      await firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .update(prescriptionModel.toJson());

      // Send notification to the patient
      final doctorDoc = await firestore.collection('medecins').doc(prescription.doctorId).get();
      final doctorName = doctorDoc.exists ? doctorDoc.data() != null?['name'] ?? 'Doctor' : 'Doctor' : 'Doctor';
      await notificationRemoteDataSource.sendNotification(
        title: 'Prescription Updated',
        body: 'Dr. $doctorName has updated your prescription.',
        senderId: prescription.doctorId,
        recipientId: prescription.patientId,
        type: NotificationType.prescriptionUpdated,
        prescriptionId: prescription.id,
        appointmentId: prescription.appointmentId,
        data: {
          'doctorName': doctorName,
        },
        recipientRole: 'patient',
      );
      print('Sent notification for updated prescription ${prescription.id} to patient ${prescription.patientId}');
    } catch (e) {
      throw ServerException('Failed to update prescription: $e');
    }
  }
}