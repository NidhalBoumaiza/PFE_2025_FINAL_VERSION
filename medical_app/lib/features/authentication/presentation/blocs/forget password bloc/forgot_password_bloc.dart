import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_remote_data_source.dart';
import 'package:medical_app/features/authentication/domain/usecases/send_verification_code_use_case.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final SendVerificationCodeUseCase sendVerificationCodeUseCase;

  ForgotPasswordBloc({required this.sendVerificationCodeUseCase}) : super(ForgotPasswordInitial()) {
    on<SendVerificationCode>(_onSendVerificationCode);
  }

  Future<void> _onSendVerificationCode(
      SendVerificationCode event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(ForgotPasswordLoading());
    final result = await sendVerificationCodeUseCase(
      email: event.email,
      codeType: event.codeType,
    );
    emit(result.fold(
          (failure) {
        if (failure is ServerFailure) {
          return ForgotPasswordError(message: 'server_error');
        } else if (failure is AuthFailure) {
          return ForgotPasswordError(message: failure.message); // Use the AuthFailure message
        } else {
          return ForgotPasswordError(message: 'unexpected_error');
        }
      },
          (_) => ForgotPasswordSuccess(),
    ));
  }
}