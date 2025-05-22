import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/data/models/user_model.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:medical_app/core/services/location_service.dart';

import '../data sources/auth_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<void> signInWithGoogle() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signInWithGoogle();
      } on AuthException catch (e) {
        throw AuthFailure(e.message);
      } on ServerException catch (e) {
        throw ServerFailure();
      }
    } else {
      throw OfflineFailure();
    }
  }

  @override
  Future<Either<Failure, Unit>> createAccount({
    required UserEntity user,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Try to get the current location
        final position = await LocationService.getCurrentPosition();
        Map<String, dynamic>? locationData;

        // If location is available, format it for Firestore
        if (position != null) {
          locationData = {
            'type': 'Point',
            'coordinates': [position.longitude, position.latitude],
          };
        }

        UserModel userModel;
        if (user is PatientEntity) {
          userModel = PatientModel(
            id: user.id,
            name: user.name,
            lastName: user.lastName,
            email: user.email,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            antecedent: user.antecedent,
            bloodType: user.bloodType,
            height: user.height,
            weight: user.weight,
            allergies: user.allergies,
            chronicDiseases: user.chronicDiseases,
            emergencyContact: user.emergencyContact,
            address: user.address,
            // Use the location data if available, otherwise use the provided location
            location: locationData ?? user.location,
          );
        } else if (user is MedecinEntity) {
          userModel = MedecinModel(
            id: user.id,
            name: user.name,
            lastName: user.lastName,
            email: user.email,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            speciality: user.speciality!,
            numLicence: user.numLicence!,
            education: user.education,
            experience: user.experience,
            consultationFee: user.consultationFee,
            address: user.address,
            // Use the location data if available, otherwise use the provided location
            location: locationData ?? user.location,
          );
        } else {
          // Reject any account creation that is not a patient or medecin
          return Left(
            AuthFailure('Only patient or doctor accounts can be created'),
          );
        }
        await remoteDataSource.createAccount(userModel, password);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on UsedEmailOrPhoneNumberException catch (e) {
        return Left(UsedEmailOrPhoneNumberFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.login(email, password);

        // Try to get the current location after successful login
        final position = await LocationService.getCurrentPosition();
        Map<String, dynamic>? locationData;

        // If location is available, format it for Firestore
        if (position != null && userModel.id != null) {
          locationData = {
            'type': 'Point',
            'coordinates': [position.longitude, position.latitude],
          };

          // Update user location in background
          if (userModel.role == 'patient') {
            LocationService.updateUserLocation(userModel.id!, 'patient');
          } else if (userModel.role == 'medecin') {
            LocationService.updateUserLocation(userModel.id!, 'medecins');
          }
        }

        UserEntity userEntity;
        if (userModel is PatientModel) {
          userEntity = PatientEntity(
            id: userModel.id,
            name: userModel.name,
            lastName: userModel.lastName,
            email: userModel.email,
            role: userModel.role,
            gender: userModel.gender,
            phoneNumber: userModel.phoneNumber,
            dateOfBirth: userModel.dateOfBirth,
            antecedent: userModel.antecedent,
            bloodType: userModel.bloodType,
            height: userModel.height,
            weight: userModel.weight,
            allergies: userModel.allergies,
            chronicDiseases: userModel.chronicDiseases,
            emergencyContact: userModel.emergencyContact,
            address: userModel.address,
            location: locationData ?? userModel.location,
          );
        } else if (userModel is MedecinModel) {
          userEntity = MedecinEntity(
            id: userModel.id,
            name: userModel.name,
            lastName: userModel.lastName,
            email: userModel.email,
            role: userModel.role,
            gender: userModel.gender,
            phoneNumber: userModel.phoneNumber,
            dateOfBirth: userModel.dateOfBirth,
            speciality: userModel.speciality,
            numLicence: userModel.numLicence,
            appointmentDuration: userModel.appointmentDuration,
            education: userModel.education,
            experience: userModel.experience,
            consultationFee: userModel.consultationFee,
            address: userModel.address,
            location: locationData ?? userModel.location,
          );
        } else {
          userEntity = UserEntity(
            id: userModel.id,
            name: userModel.name,
            lastName: userModel.lastName,
            email: userModel.email,
            role: userModel.role,
            gender: userModel.gender,
            phoneNumber: userModel.phoneNumber,
            dateOfBirth: userModel.dateOfBirth,
            address: userModel.address,
            location: locationData ?? userModel.location,
          );
        }
        return Right(userEntity);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } on UnauthorizedException {
        return Left(UnauthorizedFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on YouHaveToCreateAccountAgainException catch (e) {
        return Left(YouHaveToCreateAccountAgainFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUser(UserEntity user) async {
    if (await networkInfo.isConnected) {
      try {
        // Try to get the current location if location is not provided
        Map<String, dynamic>? locationData = user.location;
        if (locationData == null && user.id != null) {
          final position = await LocationService.getCurrentPosition();
          if (position != null) {
            locationData = {
              'type': 'Point',
              'coordinates': [position.longitude, position.latitude],
            };
          }
        }

        UserModel userModel;
        if (user is PatientEntity) {
          userModel = PatientModel(
            id: user.id!,
            name: user.name,
            lastName: user.lastName,
            email: user.email,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            antecedent: user.antecedent,
            bloodType: user.bloodType,
            height: user.height,
            weight: user.weight,
            allergies: user.allergies,
            chronicDiseases: user.chronicDiseases,
            emergencyContact: user.emergencyContact,
            address: user.address,
            location: locationData,
          );
        } else if (user is MedecinEntity) {
          userModel = MedecinModel(
            id: user.id!,
            name: user.name,
            lastName: user.lastName,
            email: user.email,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            speciality: user.speciality!,
            numLicence: user.numLicence!,
            education: user.education,
            experience: user.experience,
            consultationFee: user.consultationFee,
            address: user.address,
            location: locationData,
          );
        } else {
          userModel = UserModel(
            id: user.id!,
            name: user.name,
            lastName: user.lastName,
            email: user.email,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            address: user.address,
            location: locationData,
          );
        }
        await remoteDataSource.updateUser(userModel);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> sendVerificationCode({
    required String email,
    required VerificationCodeType codeType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendVerificationCode(
          email: email,
          codeType: codeType,
        );
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyCode({
    required String email,
    required int verificationCode,
    required VerificationCodeType codeType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyCode(
          email: email,
          verificationCode: verificationCode,
          codeType: codeType,
        );
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String email,
    required String newPassword,
    required int verificationCode,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.changePassword(
          email: email,
          newPassword: newPassword,
          verificationCode: verificationCode,
        );
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePasswordDirect({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Get Firebase Auth instance to handle the password change
        final auth = FirebaseAuth.instance;
        final user = auth.currentUser;

        if (user != null && email.isNotEmpty) {
          // Create credentials with current password
          final credential = EmailAuthProvider.credential(
            email: email,
            password: currentPassword,
          );

          // Re-authenticate user
          await user.reauthenticateWithCredential(credential);

          // Update password
          await user.updatePassword(newPassword);

          return const Right(unit);
        } else {
          return Left(AuthFailure('User not found or not authenticated'));
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          return Left(AuthFailure('Current password is incorrect'));
        } else {
          return Left(AuthFailure(e.message ?? 'Firebase auth error'));
        }
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}
