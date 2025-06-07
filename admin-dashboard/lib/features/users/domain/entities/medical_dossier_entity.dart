import 'package:equatable/equatable.dart';
import 'medical_file_entity.dart';

class MedicalDossierEntity extends Equatable {
  final List<MedicalFileEntity> files;

  const MedicalDossierEntity({required this.files});

  bool get isEmpty => files.isEmpty;
  bool get isNotEmpty => files.isNotEmpty;
  int get fileCount => files.length;

  List<MedicalFileEntity> get imageFiles =>
      files.where((file) => file.mimetype.startsWith('image/')).toList();

  List<MedicalFileEntity> get pdfFiles =>
      files.where((file) => file.mimetype == 'application/pdf').toList();

  List<MedicalFileEntity> get otherFiles =>
      files
          .where(
            (file) =>
                !file.mimetype.startsWith('image/') &&
                file.mimetype != 'application/pdf',
          )
          .toList();

  @override
  List<Object?> get props => [files];
}
