import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/features/authentication/domain/usecases/delete_account_use_case.dart';
import 'delete_account_event.dart';
import 'delete_account_state.dart';

class DeleteAccountBloc extends Bloc<DeleteAccountEvent, DeleteAccountState> {
  final DeleteAccountUseCase deleteAccountUseCase;

  DeleteAccountBloc({required this.deleteAccountUseCase})
    : super(DeleteAccountInitial()) {
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<DeleteAccountState> emit,
  ) async {
    emit(DeleteAccountLoading());

    final result = await deleteAccountUseCase(
      userId: event.userId,
      password: event.password,
    );

    result.fold(
      (failure) => emit(DeleteAccountError(message: failure.message)),
      (_) => emit(DeleteAccountSuccess()),
    );
  }
}
