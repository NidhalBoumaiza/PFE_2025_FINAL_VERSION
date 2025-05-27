import 'package:medical_app/features/dossier_medical/domain/entities/medical_file_entity.dart';

class MedicalFileModel extends MedicalFileEntity {
  const MedicalFileModel({
    required String id,
    required String filename,
    required String originalName,
    required String path,
    required String mimetype,
    required int size,
    required String description,
    required DateTime createdAt,
  }) : super(
    id: id,
    filename: filename,
    originalName: originalName,
    path: path,
    mimetype: mimetype,
    size: size,
    description: description,
    createdAt: createdAt,
  );

  factory MedicalFileModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    if (id == null || id.isEmpty) {
      throw FormatException('Missing or empty id in Firestore data: $json');
    }
    return MedicalFileModel(
      id: id,
      filename: json['filename'] ?? '',
      originalName: json['originalName'] ?? '',
      path: json['path'] ?? '',
      mimetype: json['mimetype'] ?? 'application/octet-stream',
      size: (json['size'] is int ? json['size'] : 0) as int,
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'originalName': originalName,
      'path': path,
      'mimetype': mimetype,
      'size': size,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicalFileModel.fromEntity(MedicalFileEntity entity) {
    return MedicalFileModel(
      id: entity.id,
      filename: entity.filename,
      originalName: entity.originalName,
      path: entity.path,
      mimetype: entity.mimetype,
      size: entity.size,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }

  @override
  MedicalFileEntity toEntity() {
    return MedicalFileEntity(
      id: id,
      filename: filename,
      originalName: originalName,
      path: path,
      mimetype: mimetype,
      size: size,
      description: description,
      createdAt: createdAt,
    );
  }
}