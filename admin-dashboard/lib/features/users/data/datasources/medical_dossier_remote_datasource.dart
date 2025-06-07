import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/medical_dossier_model.dart';
import '../models/medical_file_model.dart';

abstract class MedicalDossierRemoteDataSource {
  Future<MedicalDossierModel> getMedicalDossier({required String patientId});
  Future<bool> hasMedicalDossier({required String patientId});
}

class MedicalDossierRemoteDataSourceImpl
    implements MedicalDossierRemoteDataSource {
  final FirebaseFirestore firestore;

  MedicalDossierRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<MedicalDossierModel> getMedicalDossier({
    required String patientId,
  }) async {
    try {
      final patientDoc =
          await firestore.collection('patients').doc(patientId).get();

      if (!patientDoc.exists) {
        return MedicalDossierModel.empty();
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

      return MedicalDossierModel(files: files);
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get medical dossier: $e');
    }
  }

  @override
  Future<bool> hasMedicalDossier({required String patientId}) async {
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
}
