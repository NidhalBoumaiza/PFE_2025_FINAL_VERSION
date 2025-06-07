import 'package:bloc/bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_medical_dossier.dart';
import 'medical_dossier_event.dart';
import 'medical_dossier_state.dart';

class MedicalDossierBloc
    extends Bloc<MedicalDossierEvent, MedicalDossierState> {
  final GetMedicalDossier getMedicalDossier;

  MedicalDossierBloc({required this.getMedicalDossier})
    : super(const MedicalDossierInitial()) {
    on<GetMedicalDossierEvent>(_onGetMedicalDossier);
    on<ClearMedicalDossierEvent>(_onClearMedicalDossier);
  }

  Future<void> _onGetMedicalDossier(
    GetMedicalDossierEvent event,
    Emitter<MedicalDossierState> emit,
  ) async {
    emit(const MedicalDossierLoading());

    final result = await getMedicalDossier(
      GetMedicalDossierParams(patientId: event.patientId),
    );

    result.fold(
      (failure) {
        String errorMessage = 'Failed to load medical dossier';
        if (failure is ServerFailure) {
          errorMessage = failure.message ?? errorMessage;
        } else if (failure is AuthFailure) {
          errorMessage = failure.message;
        }
        emit(MedicalDossierError(message: errorMessage));
      },
      (dossier) => emit(
        MedicalDossierLoaded(dossier: dossier, patientId: event.patientId),
      ),
    );
  }

  void _onClearMedicalDossier(
    ClearMedicalDossierEvent event,
    Emitter<MedicalDossierState> emit,
  ) {
    emit(const MedicalDossierInitial());
  }
}
