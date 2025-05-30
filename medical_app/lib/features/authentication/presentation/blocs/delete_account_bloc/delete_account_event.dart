import 'package:equatable/equatable.dart';

abstract class DeleteAccountEvent extends Equatable {
  const DeleteAccountEvent();

  @override
  List<Object> get props => [];
}

class DeleteAccountRequested extends DeleteAccountEvent {
  final String userId;
  final String password;

  const DeleteAccountRequested({required this.userId, required this.password});

  @override
  List<Object> get props => [userId, password];
}
