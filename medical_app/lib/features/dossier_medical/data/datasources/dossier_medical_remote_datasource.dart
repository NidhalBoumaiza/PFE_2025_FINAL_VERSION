import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/dossier_medical/data/models/dossier_medical_model.dart';
import 'package:medical_app/features/dossier_medical/data/models/medical_file_model.dart';
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

abstract class DossierMedicalRemoteDataSource {
  Future<DossierMedicalModel> getDossierMedical({
    required String patientId,
    String? doctorId,
  });
  Future<DossierMedicalModel> addFileToDossier({
    required String patientId,
    required File file,
    required String description,
  });
  Future<DossierMedicalModel> addFilesToDossier({
    required String patientId,
    required List<File> files,
    required Map<String, String> descriptions,
  });
  Future<Unit> deleteFile({required String patientId, required String fileId});
  Future<Unit> updateFileDescription({
    required String patientId,
    required String fileId,
    required String description,
  });
  Future<bool> hasDossierMedical({required String patientId});
  Future<bool> checkDoctorAccessToPatientFiles({
    required String doctorId,
    required String patientId,
  });
}

class DossierMedicalRemoteDataSourceImpl
    implements DossierMedicalRemoteDataSource {
  final http.Client client;
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;
  final NotificationRemoteDataSource notificationRemoteDataSource;
  final Uuid uuid = Uuid();

  DossierMedicalRemoteDataSourceImpl({
    http.Client? client,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
    required this.notificationRemoteDataSource,
  }) : this.client = client ?? http.Client(),
       this.storage = storage ?? FirebaseStorage.instance,
       this.firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DossierMedicalModel> getDossierMedical({
    required String patientId,
    String? doctorId,
  }) async {
    try {
      // If doctorId is provided, check if doctor has access to patient files
      if (doctorId != null) {
        final hasAccess = await checkDoctorAccessToPatientFiles(
          doctorId: doctorId,
          patientId: patientId,
        );
        if (!hasAccess) {
          throw ServerException(
            'Access denied: Doctor does not have confirmed appointments with this patient',
          );
        }
      }

      final patientDoc =
          await firestore.collection('patients').doc(patientId).get();

      if (!patientDoc.exists) {
        return DossierMedicalModel.empty();
      }

      final patientData = patientDoc.data() ?? {};
      final List<MedicalFileModel> files =
          patientData['dossierFiles'] != null
              ? List<MedicalFileModel>.from(
                (patientData['dossierFiles'] as List).map(
                  (file) => MedicalFileModel.fromJson(file),
                ),
              )
              : [];

      return DossierMedicalModel(files: files);
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get medical dossier: $e');
    }
  }

  @override
  Future<DossierMedicalModel> addFileToDossier({
    required String patientId,
    required File file,
    required String description,
  }) async {
    try {
      // 1. Upload file to Firebase Storage
      final fileId = uuid.v4();
      final fileExtension = path.extension(file.path);
      final fileName = '$fileId$fileExtension';
      final originalName = path.basename(file.path);
      final mimeType = _getMimeType(fileExtension.replaceAll('.', ''));

      final storageRef = storage.ref().child(
        'dossiers_medicaux/$patientId/$fileName',
      );
      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {'originalName': originalName, 'patientId': patientId},
      );

      final uploadTask = storageRef.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Create file metadata
      final fileData = MedicalFileModel(
        id: fileId,
        filename: fileName,
        originalName: originalName,
        path: downloadUrl,
        mimetype: mimeType,
        size: file.lengthSync(),
        description: description,
        createdAt: DateTime.now(),
      );

      // 3. Add file to dossierFiles array
      await firestore.collection('patients').doc(patientId).set({
        'dossierFiles': FieldValue.arrayUnion([fileData.toJson()]),
      }, SetOptions(merge: true));

      // 4. Send notification to medecin
      await _sendNotification(
        patientId: patientId,
        title: 'New File Uploaded',
        body: 'A new file "$originalName" was added to the patient\'s dossier.',
        fileId: fileId,
        fileUrl: downloadUrl,
        fileName: originalName,
      );

      // 5. Return updated dossier
      final currentFiles = await getDossierMedical(patientId: patientId);
      return DossierMedicalModel(
        files: List<MedicalFileModel>.from(currentFiles.files)..add(fileData),
      );
    } on FirebaseException catch (e) {
      throw ServerException('Firestore/Storage error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to add file to dossier: $e');
    }
  }

  @override
  Future<DossierMedicalModel> addFilesToDossier({
    required String patientId,
    required List<File> files,
    required Map<String, String> descriptions,
  }) async {
    try {
      final List<MedicalFileModel> newFiles = [];
      for (var file in files) {
        final fileId = uuid.v4();
        final fileExtension = path.extension(file.path);
        final fileName = '$fileId$fileExtension';
        final originalName = path.basename(file.path);
        final mimeType = _getMimeType(fileExtension.replaceAll('.', ''));

        final storageRef = storage.ref().child(
          'dossiers_medicaux/$patientId/$fileName',
        );
        final metadata = SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'originalName': originalName,
            'patientId': patientId,
          },
        );
        final uploadTask = storageRef.putFile(file, metadata);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        final fileData = MedicalFileModel(
          id: fileId,
          filename: fileName,
          originalName: originalName,
          path: downloadUrl,
          mimetype: mimeType,
          size: file.lengthSync(),
          description: descriptions[originalName] ?? '',
          createdAt: DateTime.now(),
        );
        newFiles.add(fileData);
      }

      // Add all files to dossierFiles array
      await firestore.collection('patients').doc(patientId).set({
        'dossierFiles': FieldValue.arrayUnion(
          newFiles.map((file) => file.toJson()).toList(),
        ),
      }, SetOptions(merge: true));

      // Send notification to medecin
      await _sendNotification(
        patientId: patientId,
        title: 'Multiple Files Uploaded',
        body:
            '${newFiles.length} new files were added to the patient\'s dossier.',
        fileId: null,
        fileUrl: null,
        fileName: null,
      );

      // Return updated dossier
      final currentFiles = await getDossierMedical(patientId: patientId);
      return DossierMedicalModel(
        files: List<MedicalFileModel>.from(currentFiles.files)
          ..addAll(newFiles),
      );
    } on FirebaseException catch (e) {
      throw ServerException('Firestore/Storage error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to add multiple files to dossier: $e');
    }
  }

  @override
  Future<Unit> deleteFile({
    required String patientId,
    required String fileId,
  }) async {
    try {
      final patientDoc =
          await firestore.collection('patients').doc(patientId).get();

      if (!patientDoc.exists || patientDoc.data()?['dossierFiles'] == null) {
        throw ServerException('File not found');
      }

      final dossierFiles =
          (patientDoc.data()!['dossierFiles'] as List)
              .map((file) => MedicalFileModel.fromJson(file))
              .toList();

      final fileToDelete = dossierFiles.firstWhere(
        (file) => file.id == fileId,
        orElse: () => throw ServerException('File not found'),
      );

      final storageRef = storage.ref().child(
        'dossiers_medicaux/$patientId/${fileToDelete.filename}',
      );
      await storageRef.delete();

      await firestore.collection('patients').doc(patientId).update({
        'dossierFiles': FieldValue.arrayRemove([fileToDelete.toJson()]),
      });

      return unit;
    } on FirebaseException catch (e) {
      throw ServerException('Firestore/Storage error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to delete file: $e');
    }
  }

  @override
  Future<Unit> updateFileDescription({
    required String patientId,
    required String fileId,
    required String description,
  }) async {
    try {
      final patientDoc =
          await firestore.collection('patients').doc(patientId).get();

      if (!patientDoc.exists || patientDoc.data()?['dossierFiles'] == null) {
        throw ServerException('File not found');
      }

      final dossierFiles =
          (patientDoc.data()!['dossierFiles'] as List)
              .map((file) => MedicalFileModel.fromJson(file))
              .toList();

      final fileIndex = dossierFiles.indexWhere((file) => file.id == fileId);
      if (fileIndex == -1) {
        throw ServerException('File not found');
      }

      final fileToUpdate = dossierFiles[fileIndex];
      final updatedFile = MedicalFileModel(
        id: fileToUpdate.id,
        filename: fileToUpdate.filename,
        originalName: fileToUpdate.originalName,
        path: fileToUpdate.path,
        mimetype: fileToUpdate.mimetype,
        size: fileToUpdate.size,
        description: description,
        createdAt: fileToUpdate.createdAt,
      );

      await firestore.collection('patients').doc(patientId).update({
        'dossierFiles.$fileIndex': updatedFile.toJson(),
      });

      return unit;
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to update file description: $e');
    }
  }

  @override
  Future<bool> hasDossierMedical({required String patientId}) async {
    try {
      final patientDoc =
          await firestore.collection('patients').doc(patientId).get();

      if (!patientDoc.exists || patientDoc.data()?['dossierFiles'] == null) {
        return false;
      }

      final dossierFiles = patientDoc.data()!['dossierFiles'] as List;
      return dossierFiles.isNotEmpty;
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to check dossier existence: $e');
    }
  }

  @override
  Future<bool> checkDoctorAccessToPatientFiles({
    required String doctorId,
    required String patientId,
  }) async {
    try {
      // Check if doctor has any confirmed (accepted) appointments with the patient
      final appointmentsQuery =
          await firestore
              .collection('rendez_vous')
              .where('doctorId', isEqualTo: doctorId)
              .where('patientId', isEqualTo: patientId)
              .where('status', isEqualTo: 'accepted')
              .limit(1)
              .get();

      // If there's at least one confirmed appointment, grant access
      return appointmentsQuery.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to check doctor access: $e');
    }
  }

  Future<void> _sendNotification({
    required String patientId,
    required String title,
    required String body,
    String? fileId,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      // Fetch patient document to get medecinId and patientName
      final patientDoc =
          await firestore.collection('patients').doc(patientId).get();
      if (!patientDoc.exists) {
        print('Patient $patientId not found, skipping notification');
        return;
      }
      final patientData = patientDoc.data()!;
      final medecinId = patientData['medecinId'] as String?;
      final patientName =
          '${patientData['name']} ${patientData['lastName']}'.trim();
      if (medecinId == null) {
        print('No medecinId for patient $patientId, skipping notification');
        return;
      }

      // Fetch medecin document to verify FCM token
      final medecinDoc =
          await firestore.collection('users').doc(medecinId).get();
      if (!medecinDoc.exists || medecinDoc.data()?['fcmToken'] == null) {
        print('No FCM token for medecin $medecinId, skipping notification');
        return;
      }

      // Send notification to medecin
      await notificationRemoteDataSource.sendNotification(
        title: title,
        body: body,
        senderId: patientId,
        recipientId: medecinId,
        type: NotificationType.dossierUpdate,
        recipientRole: 'medecin',
        appointmentId: null,
        prescriptionId: null,
        ratingId: null,
        data: {
          'patientId': patientId,
          'patientName': patientName.isNotEmpty ? patientName : 'Patient',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          if (fileId != null) 'fileId': fileId,
          if (fileUrl != null) 'fileUrl': fileUrl,
          if (fileName != null) 'fileName': fileName,
        },
      );
      print('Sent notification for patient $patientId to medecin $medecinId');
    } catch (e) {
      print('Error sending notification: $e');
      // Don't fail the operation if notification fails
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
