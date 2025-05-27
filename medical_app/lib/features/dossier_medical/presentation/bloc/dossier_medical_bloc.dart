import 'package:bloc/bloc.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/add_file_to_dossier.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/add_files_to_dossier.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/delete_file.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/get_dossier_medical.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/has_dossier_medical.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/update_file_description.dart';
import 'dossier_medical_event.dart';
import 'dossier_medical_state.dart';

// BLoC for managing medical dossier operations with security checks
class DossierMedicalBloc
    extends Bloc<DossierMedicalEvent, DossierMedicalState> {
  final GetDossierMedical getDossierMedical;
  final HasDossierMedical hasDossierMedical;
  final AddFileToDossier addFileToDossier;
  final AddFilesToDossier addFilesToDossier;
  final DeleteFile deleteFile;
  final UpdateFileDescription updateFileDescription;

  // Store the current doctorId for refresh operations
  String? _currentDoctorId;

  DossierMedicalBloc({
    required this.getDossierMedical,
    required this.hasDossierMedical,
    required this.addFileToDossier,
    required this.addFilesToDossier,
    required this.deleteFile,
    required this.updateFileDescription,
  }) : super(const DossierMedicalInitial()) {
    on<FetchDossierMedicalEvent>(_onFetchDossierMedical);
    on<CheckDossierMedicalExistsEvent>(_onCheckDossierMedicalExists);
    on<UploadSingleFileEvent>(_onUploadSingleFile);
    on<UploadMultipleFilesEvent>(_onUploadMultipleFiles);
    on<DeleteFileEvent>(_onDeleteFile);
    on<UpdateFileDescriptionEvent>(_onUpdateFileDescription);
  }

  Future<void> _onFetchDossierMedical(
    FetchDossierMedicalEvent event,
    Emitter<DossierMedicalState> emit,
  ) async {
    // Store the doctorId for future refresh operations
    _currentDoctorId = event.doctorId;

    emit(const DossierMedicalLoading());
    final result = await getDossierMedical.call(
      patientId: event.patientId,
      doctorId: event.doctorId,
    );
    result.fold(
      (failure) => emit(DossierMedicalError(message: failure.message)),
      (dossier) =>
          dossier.isEmpty
              ? emit(DossierMedicalEmpty(patientId: event.patientId))
              : emit(DossierMedicalLoaded(dossier: dossier)),
    );
  }

  Future<void> _onCheckDossierMedicalExists(
    CheckDossierMedicalExistsEvent event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const CheckingDossierMedicalStatus());
    final result = await hasDossierMedical.call(patientId: event.patientId);
    result.fold(
      (failure) => emit(DossierMedicalError(message: failure.message)),
      (exists) => emit(DossierMedicalExists(exists: exists)),
    );
  }

  Future<void> _onUploadSingleFile(
    UploadSingleFileEvent event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const FileUploadLoading(isSingleFile: true));
    final result = await addFileToDossier.call(
      patientId: event.patientId,
      filePath: event.filePath,
      description: event.description,
    );
    result.fold(
      (failure) =>
          emit(FileUploadError(message: failure.message, isSingleFile: true)),
      (dossier) =>
          emit(FileUploadSuccess(dossier: dossier, isSingleFile: true)),
    );
  }

  Future<void> _onUploadMultipleFiles(
    UploadMultipleFilesEvent event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const FileUploadLoading(isSingleFile: false));
    final result = await addFilesToDossier.call(
      patientId: event.patientId,
      filePaths: event.filePaths,
      descriptions: event.descriptions,
    );
    result.fold(
      (failure) =>
          emit(FileUploadError(message: failure.message, isSingleFile: false)),
      (dossier) =>
          emit(FileUploadSuccess(dossier: dossier, isSingleFile: false)),
    );
  }

  Future<void> _onDeleteFile(
    DeleteFileEvent event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(FileDeleteLoading(fileId: event.fileId));
    final result = await deleteFile.call(
      patientId: event.patientId,
      fileId: event.fileId,
    );
    result.fold(
      (failure) =>
          emit(FileDeleteError(message: failure.message, fileId: event.fileId)),
      (_) => emit(FileDeleteSuccess(fileId: event.fileId)),
    );

    // After delete, refresh the dossier with the stored doctorId
    add(
      FetchDossierMedicalEvent(
        patientId: event.patientId,
        doctorId: _currentDoctorId,
      ),
    );
  }

  Future<void> _onUpdateFileDescription(
    UpdateFileDescriptionEvent event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(FileDescriptionUpdateLoading(fileId: event.fileId));
    final result = await updateFileDescription.call(
      patientId: event.patientId,
      fileId: event.fileId,
      description: event.description,
    );
    result.fold(
      (failure) => emit(
        FileDescriptionUpdateError(
          message: failure.message,
          fileId: event.fileId,
        ),
      ),
      (_) => emit(FileDescriptionUpdateSuccess(fileId: event.fileId)),
    );

    // After update, refresh the dossier with the stored doctorId
    add(
      FetchDossierMedicalEvent(
        patientId: event.patientId,
        doctorId: _currentDoctorId,
      ),
    );
  }
}
