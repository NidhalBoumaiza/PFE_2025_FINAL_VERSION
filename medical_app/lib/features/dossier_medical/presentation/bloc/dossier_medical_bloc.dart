import 'package:bloc/bloc.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/get_dossier_medical.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/has_dossier_medical.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../domain/repositories/dossier_medical_repository.dart';
import 'dossier_medical_event.dart';
import 'dossier_medical_state.dart';

class DossierMedicalBloc
    extends Bloc<DossierMedicalEvent, DossierMedicalState> {
  final DossierMedicalRepository repository;

  DossierMedicalBloc({required this.repository})
    : super(const DossierMedicalInitial()) {
    on<FetchDossierMedical>(_onFetchDossierMedical);
    on<CheckDossierMedicalExists>(_onCheckDossierMedicalExists);
    on<UploadSingleFile>(_onUploadSingleFile);
    on<UploadMultipleFiles>(_onUploadMultipleFiles);
    on<DeleteFile>(_onDeleteFile);
    on<UpdateFileDescription>(_onUpdateFileDescription);
  }

  Future<void> _onFetchDossierMedical(
    FetchDossierMedical event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const DossierMedicalLoading());
    final result = await repository.getDossierMedical(event.patientId);
    result.fold(
      (failure) => emit(DossierMedicalError(message: failure.message)),
      (dossier) =>
          dossier.files.isEmpty
              ? emit(DossierMedicalEmpty(patientId: event.patientId))
              : emit(DossierMedicalLoaded(dossier: dossier)),
    );
  }

  Future<void> _onCheckDossierMedicalExists(
    CheckDossierMedicalExists event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const CheckingDossierMedicalStatus());
    final result = await repository.hasDossierMedical(event.patientId);
    result.fold(
      (failure) => emit(DossierMedicalError(message: failure.message)),
      (exists) => emit(DossierMedicalExists(exists: exists)),
    );
  }

  Future<void> _onUploadSingleFile(
    UploadSingleFile event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const FileUploadLoading(isSingleFile: true));
    final result = await repository.addFileToDossier(
      event.patientId,
      event.filePath,
      event.description,
    );
    result.fold(
      (failure) =>
          emit(FileUploadError(message: failure.message, isSingleFile: true)),
      (dossier) =>
          emit(FileUploadSuccess(dossier: dossier, isSingleFile: true)),
    );
  }

  Future<void> _onUploadMultipleFiles(
    UploadMultipleFiles event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const FileUploadLoading(isSingleFile: false));
    final result = await repository.addFilesToDossier(
      event.patientId,
      event.filePaths,
      event.descriptions,
    );
    result.fold(
      (failure) =>
          emit(FileUploadError(message: failure.message, isSingleFile: false)),
      (dossier) =>
          emit(FileUploadSuccess(dossier: dossier, isSingleFile: false)),
    );
  }

  Future<void> _onDeleteFile(
    DeleteFile event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(FileDeleteLoading(fileId: event.fileId));
    final result = await repository.deleteFile(event.patientId, event.fileId);
    result.fold(
      (failure) =>
          emit(FileDeleteError(message: failure.message, fileId: event.fileId)),
      (_) => emit(FileDeleteSuccess(fileId: event.fileId)),
    );

    // After delete, refresh the dossier
    add(FetchDossierMedical(patientId: event.patientId));
  }

  Future<void> _onUpdateFileDescription(
    UpdateFileDescription event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(FileDescriptionUpdateLoading(fileId: event.fileId));
    final result = await repository.updateFileDescription(
      event.patientId,
      event.fileId,
      event.description,
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

    // After update, refresh the dossier
    add(FetchDossierMedical(patientId: event.patientId));
  }
}
