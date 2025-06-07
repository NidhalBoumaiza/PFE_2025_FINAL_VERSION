import '../../domain/entities/medical_dossier_entity.dart';
import 'medical_file_model.dart';

class MedicalDossierModel extends MedicalDossierEntity {
  const MedicalDossierModel({required super.files});

  factory MedicalDossierModel.fromJson(Map<String, dynamic> json) {
    final filesList = json['files'] as List<dynamic>? ?? [];
    return MedicalDossierModel(
      files:
          filesList
              .map(
                (file) =>
                    MedicalFileModel.fromJson(file as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  factory MedicalDossierModel.empty() {
    return const MedicalDossierModel(files: []);
  }

  Map<String, dynamic> toJson() {
    return {
      'files':
          files.map((file) => (file as MedicalFileModel).toJson()).toList(),
    };
  }

  MedicalDossierModel copyWith({List<MedicalFileModel>? files}) {
    return MedicalDossierModel(files: files ?? this.files);
  }
}
