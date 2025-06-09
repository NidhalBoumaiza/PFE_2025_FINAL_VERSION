import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/usecases/update_user_use_case.dart';

part 'update_user_event.dart';
part 'update_user_state.dart';

class UpdateUserBloc extends Bloc<UpdateUserEvent, UpdateUserState> {
  final UpdateUserUseCase updateUserUseCase;

  UpdateUserBloc({required this.updateUserUseCase})
    : super(UpdateUserInitial()) {
    on<UpdateUserEvent>((event, emit) async {
      print(
        '🔄 UpdateUserBloc: Received UpdateUserEvent for user: ${event.user.id}',
      );
      emit(UpdateUserLoading());
      print('📤 UpdateUserBloc: Emitted UpdateUserLoading state');

      final result = await updateUserUseCase(event.user);
      result.fold(
        (failure) {
          print(
            '❌ UpdateUserBloc: Update failed: ${_mapFailureToMessage(failure)}',
          );
          emit(UpdateUserFailure(_mapFailureToMessage(failure)));
        },
        (_) {
          print('✅ UpdateUserBloc: Update successful');
          emit(UpdateUserSuccess(event.user));
        },
      );
    });
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case OfflineFailure:
        return 'No internet connection';
      case AuthFailure:
        return (failure as AuthFailure).message;
      default:
        return 'Unexpected error';
    }
  }
}
