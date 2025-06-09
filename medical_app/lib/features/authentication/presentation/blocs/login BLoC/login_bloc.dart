import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain/usecases/login_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;

  LoginBloc({required this.loginUseCase}) : super(LoginInitial()) {
    on<LoginWithEmailAndPassword>(_onLoginWithEmailAndPassword);
    on<LoginWithGoogle>(_onLoginWithGoogle);
  }

  void _onLoginWithEmailAndPassword(
    LoginWithEmailAndPassword event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading(isEmailPasswordLogin: true));
    final failureOrUser = await loginUseCase(
      email: event.email,
      password: event.password,
    );
    failureOrUser.fold(
      (failure) => emit(LoginError(message: mapFailureToMessage(failure))),
      (user) => emit(LoginSuccess(user: user)),
    );
  }

  void _onLoginWithGoogle(
    LoginWithGoogle event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading(isEmailPasswordLogin: false));
    try {
      print('🔵 LoginBloc: Starting Google Sign-In process');

      await loginUseCase.authRepository.signInWithGoogle();

      // After successful Google Sign-In, get the current user from Firebase Auth
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print(
          '✅ LoginBloc: Google Sign-In successful for user: ${currentUser.email}',
        );

        // Check if this is a new user by looking at the cached data
        try {
          // Try to get the user from Firestore to check if profile is complete
          final firestore = FirebaseFirestore.instance;
          final patientDoc =
              await firestore.collection('patients').doc(currentUser.uid).get();

          if (patientDoc.exists) {
            final patientData = patientDoc.data()!;

            // Check if essential medical information is missing
            final bool needsProfileCompletion =
                patientData['height'] == null ||
                patientData['weight'] == null ||
                patientData['dateOfBirth'] == null ||
                patientData['phoneNumber'] == null ||
                patientData['phoneNumber'] == '';

            if (needsProfileCompletion) {
              print('📋 LoginBloc: Profile completion needed for Google user');
              // Create user entity with profile completion flag
              final userEntity = UserEntity(
                id: currentUser.uid,
                name: currentUser.displayName?.split(' ').first ?? 'User',
                lastName:
                    currentUser.displayName?.split(' ').skip(1).join(' ') ?? '',
                email: currentUser.email ?? '',
                role: 'patient',
                gender: patientData['gender'] ?? 'Homme',
                phoneNumber: patientData['phoneNumber'] ?? '',
                dateOfBirth: patientData['dateOfBirth']?.toDate(),
              );

              // For now, just proceed to normal login - we'll add profile completion later
              emit(LoginSuccess(user: userEntity));
              return;
            }
          }
        } catch (e) {
          print('⚠️ LoginBloc: Error checking profile completion: $e');
        }

        // Profile is complete or this is fallback - proceed normally
        final userEntity = UserEntity(
          id: currentUser.uid,
          name: currentUser.displayName?.split(' ').first ?? 'User',
          lastName: currentUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          email: currentUser.email ?? '',
          role: 'patient',
          gender: 'Homme',
          phoneNumber: currentUser.phoneNumber ?? '',
          dateOfBirth: null,
        );

        print('✅ LoginBloc: Emitting login success for Google user');
        emit(LoginSuccess(user: userEntity));
      } else {
        print('❌ LoginBloc: No current user after Google Sign-In');
        emit(const LoginError(message: 'Google Sign-In failed - no user data'));
      }
    } catch (e) {
      print('❌ LoginBloc: Google Sign-In error: $e');
      String errorMessage = 'Google Sign-In failed';

      if (e.toString().contains('cancelled')) {
        errorMessage = 'Google Sign-In was cancelled';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains(
        'account-exists-with-different-credential',
      )) {
        errorMessage =
            'An account with this email already exists with a different sign-in method. Please use email/password login.';
      } else if (e.toString().contains('invalid-credential')) {
        errorMessage = 'Invalid Google credentials. Please try again.';
      } else {
        errorMessage = e.toString();
      }

      emit(LoginError(message: errorMessage));
    }
  }
}
