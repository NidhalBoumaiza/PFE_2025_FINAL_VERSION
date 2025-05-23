import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import '../models/dossier_medical_model.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/medical_file_model.dart';

abstract class DossierMedicalRemoteDataSource {
  Future<DossierMedicalModel> getDossierMedical(String patientId);
  Future<DossierMedicalModel> addFileToDossier(
    String patientId,
    File file,
    String description,
  );
  Future<DossierMedicalModel> addFilesToDossier(
    String patientId,
    List<File> files,
    Map<String, String> descriptions,
  );
  Future<Unit> deleteFile(String patientId, String fileId);
  Future<Unit> updateFileDescription(
    String patientId,
    String fileId,
    String description,
  );
  Future<bool> hasDossierMedical(String patientId);
}

class DossierMedicalRemoteDataSourceImpl
    implements DossierMedicalRemoteDataSource {
  final http.Client client;
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;
  final String baseUrl = AppConstants.dossierMedicalEndpoint;
  final uuid = Uuid();

  DossierMedicalRemoteDataSourceImpl({
    http.Client? client,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : this.client = client ?? http.Client(),
       this.storage = storage ?? FirebaseStorage.instance,
       this.firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DossierMedicalModel> getDossierMedical(String patientId) async {
    try {
      // Get dossier document from Firestore
      final dossierDoc = await firestore
          .collection('dossiers_medicaux')
          .doc(patientId)
          .get();

      if (dossierDoc.exists) {
        // Get files collection
        final filesSnapshot = await firestore
            .collection('dossiers_medicaux')
            .doc(patientId)
            .collection('files')
            .orderBy('createdAt', descending: true)
            .get();

        // Create the dossier model
        final dossierData = dossierDoc.data() ?? {};
        final List<MedicalFileModel> files = [];

        for (var fileDoc in filesSnapshot.docs) {
          final fileData = fileDoc.data();
          files.add(MedicalFileModel.fromJson({
            'id': fileDoc.id,
            ...fileData,
          }));
        }

        return DossierMedicalModel(
          id: dossierDoc.id,
          patientId: patientId,
          files: files,
          createdAt: (dossierData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (dossierData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      } else {
        // Create empty dossier if it doesn't exist
        return DossierMedicalModel.empty(patientId);
      }
    } catch (e) {
      print('Error getting dossier medical: $e');
      throw ServerException('Failed to get medical dossier: $e');
    }
  }

  @override
  Future<DossierMedicalModel> addFileToDossier(
    String patientId,
    File file,
    String description,
  ) async {
    try {
      // 1. Upload file to Firebase Storage
      final fileId = uuid.v4();
      final fileExtension = path.extension(file.path);
      final fileName = '$fileId$fileExtension';
      final originalName = path.basename(file.path);
      final mimeType = _getMimeType(fileExtension.replaceAll('.', ''));
      
      // Create storage reference
      final storageRef = storage.ref().child('dossiers_medicaux/$patientId/$fileName');
      
      // Set metadata
      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'originalName': originalName,
          'patientId': patientId,
        },
      );
      
      // Upload file
      final uploadTask = storageRef.putFile(file, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // 2. Create or update dossier document in Firestore
      final dossierRef = firestore.collection('dossiers_medicaux').doc(patientId);
      final now = DateTime.now();
      
      await dossierRef.set({
        'patientId': patientId,
        'updatedAt': now,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // 3. Add file document to files subcollection
      final fileData = {
        'filename': fileName,
        'originalName': originalName,
        'path': downloadUrl,
        'mimetype': mimeType,
        'size': file.lengthSync(),
        'description': description,
        'createdAt': now,
      };
      
      await dossierRef.collection('files').doc(fileId).set(fileData);
      
      // 4. Return updated dossier
      return getDossierMedical(patientId);
    } catch (e) {
      print('Error adding file to dossier: $e');
      throw ServerException('Failed to add file to dossier: $e');
    }
  }

  @override
  Future<DossierMedicalModel> addFilesToDossier(
    String patientId,
    List<File> files,
    Map<String, String> descriptions,
  ) async {
    try {
      // Process each file
      for (var file in files) {
        final fileName = path.basename(file.path);
        final description = descriptions[fileName] ?? '';
        
        // Upload each file individually
        await addFileToDossier(patientId, file, description);
      }
      
      // Return the updated dossier
      return getDossierMedical(patientId);
    } catch (e) {
      print('Error adding multiple files to dossier: $e');
      throw ServerException('Failed to add multiple files to dossier: $e');
    }
  }

  @override
  Future<Unit> deleteFile(String patientId, String fileId) async {
    try {
      // 1. Get the file document to get the filename
      final fileDoc = await firestore
          .collection('dossiers_medicaux')
          .doc(patientId)
          .collection('files')
          .doc(fileId)
          .get();
      
      if (!fileDoc.exists) {
        throw ServerException('File not found');
      }
      
      final fileData = fileDoc.data()!;
      final fileName = fileData['filename'] as String;
      
      // 2. Delete the file from Firebase Storage
      final storageRef = storage.ref().child('dossiers_medicaux/$patientId/$fileName');
      await storageRef.delete();
      
      // 3. Delete the file document from Firestore
      await firestore
          .collection('dossiers_medicaux')
          .doc(patientId)
          .collection('files')
          .doc(fileId)
          .delete();
      
      // 4. Update the dossier's updatedAt field
      await firestore
          .collection('dossiers_medicaux')
          .doc(patientId)
          .update({'updatedAt': FieldValue.serverTimestamp()});
      
      return unit;
    } catch (e) {
      print('Error deleting file: $e');
      throw ServerException('Failed to delete file: $e');
    }
  }

  @override
  Future<Unit> updateFileDescription(
    String patientId,
    String fileId,
    String description,
  ) async {
    try {
      // Update the file document in Firestore
      await firestore
          .collection('dossiers_medicaux')
          .doc(patientId)
          .collection('files')
          .doc(fileId)
          .update({
        'description': description,
      });
      
      // Update the dossier's updatedAt field
      await firestore
          .collection('dossiers_medicaux')
          .doc(patientId)
          .update({'updatedAt': FieldValue.serverTimestamp()});
      
      return unit;
    } catch (e) {
      print('Error updating file description: $e');
      throw ServerException('Failed to update file description: $e');
    }
  }

  @override
  Future<bool> hasDossierMedical(String patientId) async {
    try {
      final dossierDoc = await firestore
          .collection('dossiers_medicaux')
          .doc(patientId)
          .get();
      
      if (!dossierDoc.exists) {
        return false;
      }
      
      // Check if there are any files
      final filesSnapshot = await firestore
          .collection('dossiers_medicaux')
          .doc(patientId)
          .collection('files')
          .limit(1)
          .get();
      
      return filesSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if dossier exists: $e');
      return false;
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
