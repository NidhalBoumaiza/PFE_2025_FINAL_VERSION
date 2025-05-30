part of 'signup_bloc.dart';

abstract class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object> get props => [];
}

class SignupWithUserEntity extends SignupEvent {
  final UserEntity user;
  final String password;

  const SignupWithUserEntity({required this.user, required this.password});

  @override
  List<Object> get props => [user, password];
}

class SignupWithProfilePicture extends SignupEvent {
  final UserEntity user;
  final String password;
  final File? profilePicture;

  const SignupWithProfilePicture({
    required this.user,
    required this.password,
    this.profilePicture,
  });

  @override
  List<Object> get props => [
    user,
    password,
    if (profilePicture != null) profilePicture!,
  ];
}
