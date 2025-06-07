import 'package:equatable/equatable.dart';

class MedicalFileEntity extends Equatable {
  final String id;
  final String filename;
  final String originalName;
  final String path; // Download URL
  final String mimetype;
  final int size;
  final String description;
  final DateTime createdAt;

  const MedicalFileEntity({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.path,
    required this.mimetype,
    required this.size,
    required this.description,
    required this.createdAt,
  });

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get fileTypeIcon {
    if (mimetype.startsWith('image/')) return 'image';
    if (mimetype == 'application/pdf') return 'pdf';
    return 'file';
  }

  @override
  List<Object?> get props => [
    id,
    filename,
    originalName,
    path,
    mimetype,
    size,
    description,
    createdAt,
  ];
}
