part of 'forgot_password_bloc.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object> get props => [];
}

class SendVerificationCode extends ForgotPasswordEvent {
  final String email;
  final VerificationCodeType codeType;

  const SendVerificationCode({
    required this.email,
    required this.codeType,
  });

  @override
  List<Object> get props => [email, codeType];
}