import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/usecases/change_password_use_case.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ChangePasswordUseCase changePasswordUseCase;

  ResetPasswordBloc({required this.changePasswordUseCase}) : super(ResetPasswordInitial()) {
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
  }

  Future<void> _onResetPasswordSubmitted(
      ResetPasswordSubmitted event,
      Emitter<ResetPasswordState> emit,
      ) async {
    print('ResetPasswordBloc: Handling ResetPasswordSubmitted: email=${event.email}, code=${event.verificationCode}');
    emit(ResetPasswordLoading());
    final result = await changePasswordUseCase(
      email: event.email,
      newPassword: event.newPassword,
      verificationCode: event.verificationCode,
    );
    print('ResetPasswordBloc: Result=$result');
    result.fold(
          (failure) {
        if (failure is ServerFailure) {
          emit(ResetPasswordError(message: 'server_error'));
        } else if (failure is AuthFailure) {
          emit(ResetPasswordError(message: failure.message));
        } else {
          emit(ResetPasswordError(message: 'unexpected_error'));
        }
      },
          (_) => emit(ResetPasswordSuccess()),
    );
  }
}