import 'package:equatable/equatable.dart';

/// Represents a medical file stored in the 'dossierFiles' array of a patient's
/// document in Firestore, with the actual file stored in Firebase Storage.
class MedicalFileEntity extends Equatable {
  /// The unique ID of the file within the dossierFiles array.
  final String id;

  /// The name of the file as stored in Firebase Storage (UUID + extension).
  final String filename;

  /// The original name of the file as uploaded by the user.
  final String originalName;

  /// The Firebase Storage download URL for accessing the file.
  final String path;

  /// The MIME type of the file (e.g., 'image/jpeg', 'application/pdf').
  final String mimetype;

  /// The size of the file in bytes, stored as an integer.
  final int size;

  /// The description of the file, stored in Firestore.
  final String description;

  /// Timestamp when the file was added, stored in Firestore.
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
  }) : assert(size >= 0, 'File size must be non-negative');

  /// Indicates if the file is an image based on MIME type.
  bool get isImage => mimetype.startsWith('image/');

  /// Indicates if the file is a PDF based on MIME type.
  bool get isPdf => mimetype == 'application/pdf';

  /// Returns the file type for display purposes.
  String get fileType {
    if (isImage) return 'Image';
    if (isPdf) return 'PDF';
    return 'Document';
  }

  /// Formats the file size for display (e.g., KB, MB).
  String get fileSize {
    if (size < 1024) return '$size B';
    if (size < 1048576) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1048576).toStringAsFixed(1)} MB';
  }

  /// Returns the display name (original name if available, else filename).
  String get displayName => originalName.isNotEmpty ? originalName : filename;

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