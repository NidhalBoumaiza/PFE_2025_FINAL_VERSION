part of 'update_user_bloc.dart';

class UpdateUserEvent extends Equatable {
  final UserEntity user;

  const UpdateUserEvent(this.user);

  @override
  List<Object> get props => [user];
}