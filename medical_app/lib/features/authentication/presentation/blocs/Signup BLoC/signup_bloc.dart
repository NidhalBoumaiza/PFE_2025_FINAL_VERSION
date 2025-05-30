import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/usecases/create_account_use_case.dart';
import 'package:medical_app/features/authentication/data/data sources/profile_picture_service.dart';

import '../../../../../core/utils/map_failure_to_message.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final CreateAccountUseCase createAccountUseCase;
  final ProfilePictureService profilePictureService;

  SignupBloc({
    required this.createAccountUseCase,
    required this.profilePictureService,
  }) : super(SignupInitial()) {
    on<SignupWithUserEntity>(_onSignupWithUserEntity);
    on<SignupWithProfilePicture>(_onSignupWithProfilePicture);
  }

  void _onSignupWithUserEntity(
    SignupWithUserEntity event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoading());
    final failureOrUnit = await createAccountUseCase(
      event.user,
      event.password,
    );
    failureOrUnit.fold(
      (failure) => emit(SignupError(message: mapFailureToMessage(failure))),
      (_) => emit(SignupSuccess()),
    );
  }

  void _onSignupWithProfilePicture(
    SignupWithProfilePicture event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoading());
    
    try {
      // First create the user account
      final failureOrUnit = await createAccountUseCase(
        event.user,
        event.password,
      );
      
      await failureOrUnit.fold(
        (failure) async {
          emit(SignupError(message: mapFailureToMessage(failure)));
        },
        (unit) async {
          // If user creation successful and profile picture provided, upload it
          if (event.profilePicture != null && event.user.id != null) {
            try {
              // Upload profile picture
              final profilePictureUrl = await profilePictureService.uploadProfilePicture(
                userId: event.user.id!,
                imageFile: event.profilePicture!,
              );
              
              // Update user document with profile picture URL
              await profilePictureService.updateUserProfilePicture(
                userId: event.user.id!,
                profilePictureUrl: profilePictureUrl,
              );
              
              emit(SignupSuccess());
            } catch (e) {
              // If profile picture upload fails, still consider signup successful
              // but emit a warning or different state if needed
              print('Profile picture upload failed: $e');
              emit(SignupSuccess()); // Could be SignupSuccessWithWarning if you create that state
            }
          } else {
            // No profile picture to upload
            emit(SignupSuccess());
          }
        },
      );
    } catch (e) {
      emit(SignupError(message: 'Unexpected error during signup: $e'));
    }
  }
}
