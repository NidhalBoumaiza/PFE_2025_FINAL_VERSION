import 'package:medical_app/features/dossier_medical/domain/entities/dossier_files_entity.dart';
import 'medical_file_model.dart';

class DossierMedicalModel extends DossierFilesEntity {
  const DossierMedicalModel({
    required List<MedicalFileModel> files,
  }) : super(files: files);

  factory DossierMedicalModel.fromJson(Map<String, dynamic> json) {
    return DossierMedicalModel(
      files: json['dossierFiles'] != null
          ? List<MedicalFileModel>.from(
        (json['dossierFiles'] as List).map(
              (file) => MedicalFileModel.fromJson(file),
        ),
      )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dossierFiles': files.map((file) => (file as MedicalFileModel).toJson()).toList(),
    };
  }

  factory DossierMedicalModel.empty() {
    return const DossierMedicalModel(files: []);
  }
}