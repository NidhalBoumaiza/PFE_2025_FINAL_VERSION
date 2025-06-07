import '../../domain/entities/medical_file_entity.dart';

class MedicalFileModel extends MedicalFileEntity {
  const MedicalFileModel({
    required super.id,
    required super.filename,
    required super.originalName,
    required super.path,
    required super.mimetype,
    required super.size,
    required super.description,
    required super.createdAt,
  });

  factory MedicalFileModel.fromJson(Map<String, dynamic> json) {
    return MedicalFileModel(
      id: json['id'] ?? '',
      filename: json['filename'] ?? '',
      originalName: json['originalName'] ?? '',
      path: json['path'] ?? '',
      mimetype: json['mimetype'] ?? '',
      size: json['size']?.toInt() ?? 0,
      description: json['description'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
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

  MedicalFileModel copyWith({
    String? id,
    String? filename,
    String? originalName,
    String? path,
    String? mimetype,
    int? size,
    String? description,
    DateTime? createdAt,
  }) {
    return MedicalFileModel(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      originalName: originalName ?? this.originalName,
      path: path ?? this.path,
      mimetype: mimetype ?? this.mimetype,
      size: size ?? this.size,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
