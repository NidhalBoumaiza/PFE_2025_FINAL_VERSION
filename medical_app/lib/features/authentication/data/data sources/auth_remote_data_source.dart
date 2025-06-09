import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/data/models/user_model.dart';
import 'package:medical_app/constants.dart';
import 'auth_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VerificationCodeType {
  compteActive,
  activationDeCompte,
  motDePasseOublie,
  changerMotDePasse,
}

abstract class AuthRemoteDataSource {
  Future<void> signInWithGoogle();
  Future<Unit> createAccount(UserModel user, String password);
  Future<UserModel> login(String email, String password);
  Future<Unit> updateUser(UserModel user);
  Future<Unit> sendVerificationCode({
    required String email,
    required VerificationCodeType codeType,
  });
  Future<Unit> verifyCode({
    required String email,
    required int verificationCode,
    required VerificationCodeType codeType,
  });
  Future<Unit> changePassword({
    required String email,
    required String newPassword,
    required int verificationCode,
  });
  Future<Unit> deleteAccount({
    required String userId,
    required String password,
  });
  Future<void> updateUserTokenAndLocation({
    required String userId,
    String? fcmToken,
    Map<String, dynamic>? location,
    Map<String, dynamic>? address,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;
  final AuthLocalDataSource localDataSource;
  final String emailServiceUrl = AppConstants.usersEndpoint;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
    required this.localDataSource,
  });

  int generateFourDigitNumber() {
    final random = Random();
    return 1000 + random.nextInt(9000);
  }

  String getSubjectForCodeType(VerificationCodeType codeType) {
    switch (codeType) {
      case VerificationCodeType.compteActive:
        return 'Compte Activé';
      case VerificationCodeType.activationDeCompte:
        return 'Activation de compte';
      case VerificationCodeType.motDePasseOublie:
        return 'Mot de passe oublié';
      case VerificationCodeType.changerMotDePasse:
        return 'Changer mot de passe';
    }
  }

  Future<void> sendVerificationEmail({
    required String email,
    required String subject,
    required int code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$emailServiceUrl/sendMailService'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'subject': subject, 'code': code}),
      );
      if (response.statusCode != 201) {
        throw ServerException(
          'Failed to send verification email: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException('Unexpected error sending email: $e');
    }
  }

  Future<void> clearVerificationCode({
    required String collection,
    required String docId,
  }) async {
    await firestore.collection(collection).doc(docId).update({
      'verificationCode': null,
      'validationCodeExpiresAt': null,
    });
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In process');

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Google Sign-In cancelled by user');
        throw AuthException('Google Sign-In cancelled');
      }

      print('✅ Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Signing in with Google credentials to Firebase');
      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        print('✅ Firebase user created/signed in: ${user.uid}');

        // Check if this is a new user or existing user
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        print('👤 Is new user: $isNewUser');

        final normalizedEmail = user.email?.toLowerCase().trim() ?? '';

        if (isNewUser) {
          // New user - create patient account with activation required
          print('🆕 Creating new patient account for Google user');

          // Check if email already exists in patients or medecins collections
          final existingPatient =
              await firestore
                  .collection('patients')
                  .where('email', isEqualTo: normalizedEmail)
                  .get();

          final existingMedecin =
              await firestore
                  .collection('medecins')
                  .where('email', isEqualTo: normalizedEmail)
                  .get();

          if (existingPatient.docs.isNotEmpty ||
              existingMedecin.docs.isNotEmpty) {
            print('❌ Email already exists in patients or medecins collection');
            // Sign out the user and throw error
            await firebaseAuth.signOut();
            await googleSignIn.signOut();
            throw AuthException(
              'An account with this email already exists. Please use email/password login.',
            );
          }

          // Get FCM token if available
          final prefs = await SharedPreferences.getInstance();
          final fcmToken = prefs.getString('FCM_TOKEN');

          // Create patient data - account needs activation
          final patientData = PatientModel(
            id: user.uid,
            name: user.displayName?.split(' ').first ?? 'User',
            lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
            email: normalizedEmail,
            role: 'patient',
            gender: 'Homme', // Default - user can update later
            phoneNumber: user.phoneNumber ?? '',
            dateOfBirth: null,
            antecedent: '',
            bloodType: null,
            height: null,
            weight: null,
            allergies: [],
            chronicDiseases: [],
            emergencyContact: null,
            address: null,
            location: null,
            accountStatus: true, // Google accounts are auto-activated
            verificationCode: null,
            validationCodeExpiresAt: null,
            fcmToken: fcmToken,
          );

          print('💾 Saving patient data to Firestore');
          await firestore
              .collection('patients')
              .doc(user.uid)
              .set(patientData.toJson());

          // Create minimal user data for notifications
          Map<String, dynamic> userDataForNotifications = {
            'id': user.uid,
            'name': patientData.name,
            'lastName': patientData.lastName,
            'email': normalizedEmail,
            'role': 'patient',
          };

          if (fcmToken != null && fcmToken.isNotEmpty) {
            userDataForNotifications['fcmToken'] = fcmToken;
          }

          await firestore
              .collection('users')
              .doc(user.uid)
              .set(userDataForNotifications);

          print('💾 Cached user data locally');
          await localDataSource.cacheUser(patientData);
          await localDataSource.saveToken(user.uid);

          print('✅ New Google patient account created successfully');
        } else {
          // Existing user - fetch their data from Firestore
          print('👤 Existing user - fetching user data');

          // Try to find user in patients collection first
          final patientDoc =
              await firestore.collection('patients').doc(user.uid).get();

          if (patientDoc.exists) {
            print('📋 Found existing patient data');
            final patientData = PatientModel.fromJson(
              patientDoc.data()! as Map<String, dynamic>,
            );

            // Update FCM token if available
            final prefs = await SharedPreferences.getInstance();
            final fcmToken = prefs.getString('FCM_TOKEN');

            if (fcmToken != null && fcmToken.isNotEmpty) {
              await firestore.collection('patients').doc(user.uid).update({
                'fcmToken': fcmToken,
              });

              await firestore.collection('users').doc(user.uid).update({
                'fcmToken': fcmToken,
              });
            }

            await localDataSource.cacheUser(patientData);
            await localDataSource.saveToken(user.uid);

            print('✅ Existing patient login successful');
          } else {
            // Try medecins collection
            final medecinDoc =
                await firestore.collection('medecins').doc(user.uid).get();

            if (medecinDoc.exists) {
              print('👨‍⚕️ Found existing medecin data');
              final medecinData = MedecinModel.fromJson(
                medecinDoc.data()! as Map<String, dynamic>,
              );

              // Update FCM token if available
              final prefs = await SharedPreferences.getInstance();
              final fcmToken = prefs.getString('FCM_TOKEN');

              if (fcmToken != null && fcmToken.isNotEmpty) {
                await firestore.collection('medecins').doc(user.uid).update({
                  'fcmToken': fcmToken,
                });

                await firestore.collection('users').doc(user.uid).update({
                  'fcmToken': fcmToken,
                });
              }

              await localDataSource.cacheUser(medecinData);
              await localDataSource.saveToken(user.uid);

              print('✅ Existing medecin login successful');
            } else {
              print('❌ No user data found in either collection');
              // This shouldn't happen - create patient account as fallback
              final userData = UserModel(
                id: user.uid,
                name: user.displayName?.split(' ').first ?? 'User',
                lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
                email: normalizedEmail,
                role: 'patient',
                gender: 'Homme',
                phoneNumber: user.phoneNumber ?? '',
                dateOfBirth: null,
              );

              await firestore
                  .collection('users')
                  .doc(user.uid)
                  .set(userData.toJson());
              await localDataSource.cacheUser(userData);
              await localDataSource.saveToken(user.uid);

              print('⚠️ Created fallback user account');
            }
          }
        }

        print('🎉 Google Sign-In completed successfully');
      } else {
        print('❌ Firebase user is null after credential sign-in');
        throw AuthException('Google Sign-In failed - no user data');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      if (e.code == 'account-exists-with-different-credential') {
        throw AuthException(
          'An account with this email already exists with a different sign-in method. Please use email/password login.',
        );
      } else if (e.code == 'invalid-credential') {
        throw AuthException('Invalid Google credentials. Please try again.');
      } else {
        throw AuthException(e.message ?? 'Google Sign-In failed');
      }
    } catch (e) {
      print('❌ Unexpected error during Google Sign-In: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw ServerException('Unexpected error during Google Sign-In: $e');
    }
  }

  @override
  Future<Unit> createAccount(UserModel user, String password) async {
    try {
      print('createAccount: Starting for email=${user.email}');
      final normalizedEmail = user.email.toLowerCase().trim();

      // Check only patients and medecins collections for existing email or phone
      final collections = ['patients', 'medecins'];
      for (var collection in collections) {
        print(
          'createAccount: Checking collection=$collection for email=$normalizedEmail',
        );
        final emailQuery =
            await firestore
                .collection(collection)
                .where('email', isEqualTo: normalizedEmail)
                .get();
        print(
          'createAccount: Email query result: ${emailQuery.docs.length} docs found',
        );
        if (emailQuery.docs.isNotEmpty) {
          throw UsedEmailOrPhoneNumberException('Email already used');
        }
        if (user.phoneNumber.isNotEmpty) {
          print('createAccount: Checking phoneNumber=${user.phoneNumber}');
          final phoneQuery =
              await firestore
                  .collection(collection)
                  .where('phoneNumber', isEqualTo: user.phoneNumber)
                  .get();
          print(
            'createAccount: Phone query result: ${phoneQuery.docs.length} docs found',
          );
          if (phoneQuery.docs.isNotEmpty) {
            throw UsedEmailOrPhoneNumberException('Phone number already used');
          }
        }
      }

      print(
        'createAccount: Creating Firebase Auth user with email=$normalizedEmail',
      );
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        print('createAccount: Firebase user created, UID=${firebaseUser.uid}');
        final randomNumber = generateFourDigitNumber();
        print('createAccount: Generated verificationCode=$randomNumber');

        // Determine collection based on user type (only patient or medecin)
        final collection = user is PatientModel ? 'patients' : 'medecins';
        print('createAccount: Using collection=$collection');

        // Get FCM token from SharedPreferences if available
        final prefs = await SharedPreferences.getInstance();
        final fcmToken = prefs.getString('FCM_TOKEN');

        UserModel updatedUser;
        if (user is PatientModel) {
          updatedUser = PatientModel(
            id: firebaseUser.uid,
            name: user.name,
            lastName: user.lastName,
            email: normalizedEmail,
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
            location: user.location,
            accountStatus: false,
            verificationCode: randomNumber,
            validationCodeExpiresAt: DateTime.now().add(
              const Duration(minutes: 60),
            ),
            fcmToken: user.fcmToken,
          );
        } else if (user is MedecinModel) {
          updatedUser = MedecinModel(
            id: firebaseUser.uid,
            name: user.name,
            lastName: user.lastName,
            email: normalizedEmail,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            speciality: user.speciality,
            numLicence: user.numLicence,
            appointmentDuration: user.appointmentDuration,
            education: user.education,
            experience: user.experience,
            consultationFee: user.consultationFee,
            address: user.address,
            location: user.location,
            accountStatus: false,
            verificationCode: randomNumber,
            validationCodeExpiresAt: DateTime.now().add(
              const Duration(minutes: 60),
            ),
            fcmToken: user.fcmToken,
          );
        } else {
          // This should never happen as we filter at the repository level
          throw AuthException('Only patient or doctor accounts can be created');
        }

        // Create user document with FCM token if available
        Map<String, dynamic> userData = updatedUser.toJson();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          userData['fcmToken'] = fcmToken;
          print('createAccount: Added FCM token to user data: $fcmToken');
        }

        print('createAccount: Saving user to Firestore');
        await firestore
            .collection(collection)
            .doc(firebaseUser.uid)
            .set(userData);

        // Also save minimal data to users collection for notification service
        Map<String, dynamic> userDataForUsers = {
          'id': updatedUser.id,
          'name': updatedUser.name,
          'lastName': updatedUser.lastName,
          'email': normalizedEmail,
          'role': updatedUser.role,
        };

        if (fcmToken != null && fcmToken.isNotEmpty) {
          userDataForUsers['fcmToken'] = fcmToken;
        }

        // Save minimal user data to 'users' collection for notification service only
        await firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userDataForUsers);
        print(
          'createAccount: Saved minimal user data to users collection for notifications',
        );

        print('createAccount: Caching user locally');
        await localDataSource.cacheUser(updatedUser);
        print('createAccount: Saving token');
        await localDataSource.saveToken(firebaseUser.uid);
        print('createAccount: Sending verification code');
        // await sendVerificationCode(
        //   email: normalizedEmail,
        //   codeType: VerificationCodeType.activationDeCompte,
        // );
        print('createAccount: Completed successfully');
        return unit;
      } else {
        print('createAccount: Error - Firebase user creation failed');
        throw AuthException('User creation failed');
      }
    } on FirebaseAuthException catch (e) {
      print(
        'createAccount: FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      if (e.code == 'email-already-in-use') {
        throw UsedEmailOrPhoneNumberException('Email already in use');
      } else if (e.code == 'weak-password') {
        throw AuthException('Password is too weak');
      } else {
        throw AuthException(e.message ?? 'Account creation failed');
      }
    } catch (e) {
      print('createAccount: Unexpected error: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      print('login: Starting for email=$email');

      // Print detailed debug info
      print(
        'login: Debug - Using Firebase Auth instance: ${firebaseAuth.hashCode}',
      );
      print(
        'login: Debug - Current user before login: ${firebaseAuth.currentUser?.uid}',
      );

      // First, sign out to ensure a clean state
      try {
        if (firebaseAuth.currentUser != null) {
          print('login: Debug - Signing out current user first');
          await firebaseAuth.signOut();
        }
      } catch (e) {
        print('login: Debug - Error during signout: $e');
      }

      final normalizedEmail = email.toLowerCase().trim();
      print('login: Debug - Normalized email: $normalizedEmail');
      print('login: Debug - Password length: ${password.length}');

      // Attempt login with error handling
      UserCredential? userCredential;
      try {
        print('login: Debug - Attempting signInWithEmailAndPassword');
        userCredential = await firebaseAuth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        print('login: Debug - SignIn successful: ${userCredential.user?.uid}');
      } catch (signInError) {
        print('login: Debug - SignIn error: $signInError');
        rethrow;
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        print('login: Firebase user signed in, UID=${firebaseUser.uid}');

        // Get the FCM token from SharedPreferences if available
        final prefs = await SharedPreferences.getInstance();
        final fcmToken = prefs.getString('FCM_TOKEN');

        // Initialize user and collection variables
        UserModel? user;
        String? collection;

        // Try to get user from patients collection
        try {
          print('login: Debug - Checking patient collection');
          final patientDoc =
              await firestore
                  .collection('patients')
                  .doc(firebaseUser.uid)
                  .get();

          if (patientDoc.exists) {
            print('login: Debug - Patient document exists');
            print('login: Debug - Patient data: ${patientDoc.data()}');

            try {
              user = PatientModel.fromJson(patientDoc.data()!);
              collection = 'patients';
              print('login: Found user in patients, email=${user.email}');

              if (user.accountStatus != true) {
                print('login: Error - Patient account is not activated');
                throw AuthException(
                  'Account is not activated. Please verify your email.',
                );
              }
            } catch (e) {
              print('login: Error parsing patient data: $e');

              // Use the recovery method to create a valid model
              user = PatientModel.recoverFromCorruptDoc(
                patientDoc.data(),
                firebaseUser.uid,
                normalizedEmail,
              );
              collection = 'patients';

              // Update the Firestore document with valid data
              await firestore
                  .collection('patients')
                  .doc(firebaseUser.uid)
                  .set(user.toJson());
              print('login: Debug - Patient data recovered and saved');
            }
          }
        } catch (e) {
          print('login: Error checking patient collection: $e');
        }

        // If user not found in patients, try medecins
        if (user == null) {
          try {
            print('login: Debug - Checking medecin collection');
            final medecinDoc =
                await firestore
                    .collection('medecins')
                    .doc(firebaseUser.uid)
                    .get();

            if (medecinDoc.exists) {
              print('login: Debug - Medecin document exists');
              print('login: Debug - Medecin data: ${medecinDoc.data()}');

              try {
                user = MedecinModel.fromJson(medecinDoc.data()!);
                collection = 'medecins';
                print('login: Found user in medecins, email=${user.email}');

                if (user.accountStatus != true) {
                  print('login: Error - Doctor account is not activated');
                  throw AuthException(
                    'Account is not activated. Please verify your email.',
                  );
                }
              } catch (e) {
                print('login: Error parsing medecin data: $e');

                // Use the recovery method to create a valid model
                user = MedecinModel.recoverFromCorruptDoc(
                  medecinDoc.data(),
                  firebaseUser.uid,
                  normalizedEmail,
                );
                collection = 'medecins';

                // Update the Firestore document with valid data
                await firestore
                    .collection('medecins')
                    .doc(firebaseUser.uid)
                    .set(user.toJson());
                print('login: Debug - Medecin data recovered and saved');
              }
            }
          } catch (e) {
            print('login: Error checking medecin collection: $e');
          }
        }

        // If still no user found, try users collection or create new one
        if (user == null) {
          try {
            print(
              'login: Debug - Checking users collection or creating new user',
            );
            final userDoc =
                await firestore.collection('users').doc(firebaseUser.uid).get();

            if (userDoc.exists) {
              print('login: Debug - User exists in users collection');

              // Determine role from users collection
              final role = userDoc.data()?['role'] as String? ?? 'patient';

              if (role == 'medecin') {
                // Create new medecin record using recovery method
                user = MedecinModel.recoverFromCorruptDoc(
                  userDoc.data(),
                  firebaseUser.uid,
                  normalizedEmail,
                );
                collection = 'medecins';
              } else {
                // Create new patient record using recovery method
                user = PatientModel.recoverFromCorruptDoc(
                  userDoc.data(),
                  firebaseUser.uid,
                  normalizedEmail,
                );
                collection = 'patients';
              }

              // Save to appropriate collection
              await firestore
                  .collection(collection!)
                  .doc(firebaseUser.uid)
                  .set(user.toJson());
              print(
                'login: Debug - Created new $collection record from users collection',
              );
            } else {
              // No record found anywhere, create new patient account
              print(
                'login: Debug - No user data found in any collection, creating new patient',
              );
              user = PatientModel.recoverFromCorruptDoc(
                {
                  'name': firebaseUser.displayName?.split(' ').first,
                  'lastName': firebaseUser.displayName?.split(' ').last,
                },
                firebaseUser.uid,
                normalizedEmail,
              );
              collection = 'patients';

              // Save to patients collection
              await firestore
                  .collection('patients')
                  .doc(firebaseUser.uid)
                  .set(user.toJson());
              print('login: Debug - Created new patient record from auth data');
            }
          } catch (e) {
            print('login: Error trying to recover or create user: $e');
            throw AuthException(
              'Failed to recover account data. Please contact support.',
            );
          }
        }

        // At this point we must have a valid user and collection
        if (user == null || collection == null) {
          throw AuthException(
            'Failed to establish user identity. Please contact support.',
          );
        }

        // Save the FCM token if it's available, but only in the patient or medecin collection
        if (fcmToken != null && fcmToken.isNotEmpty) {
          // Update the FCM token in the appropriate collection
          try {
            await firestore.collection(collection).doc(firebaseUser.uid).update(
              {'fcmToken': fcmToken},
            );
            print('login: Updated FCM token for user: $fcmToken');
          } catch (e) {
            print('login: Warning - Failed to update FCM token: $e');
          }

          // Also keep minimal data in users collection only for notification purposes
          try {
            await firestore.collection('users').doc(firebaseUser.uid).set({
              'id': user.id,
              'name': user.name,
              'lastName': user.lastName,
              'email': user.email,
              'role': user.role,
              'fcmToken': fcmToken,
            }, SetOptions(merge: true));
            print(
              'login: Updated minimal user data in users collection for notifications',
            );
          } catch (e) {
            // Log error but continue, as this is not critical for login
            print(
              'login: Warning - Failed to update users collection for notifications: $e',
            );
          }
        } else {
          print('login: No FCM token available to update');
        }

        // Cache user data locally
        await localDataSource.cacheUser(user);
        await localDataSource.saveToken(firebaseUser.uid);
        print('login: Debug - Login successful, returning user model');
        return user;
      } else {
        print('login: Error - Firebase sign-in failed');
        throw AuthException('Login failed');
      }
    } on FirebaseAuthException catch (e) {
      print(
        'login: FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      if (e.code == 'user-not-found') {
        throw UnauthorizedException(
          'Account not found. Please check your email.',
        );
      } else if (e.code == 'wrong-password') {
        throw UnauthorizedException('Incorrect password. Please try again.');
      } else if (e.code == 'user-disabled') {
        throw AuthException('This account has been disabled.');
      } else if (e.code == 'too-many-requests') {
        throw AuthException(
          'Too many unsuccessful login attempts. Please try again later.',
        );
      } else if (e.code == 'invalid-credential') {
        throw AuthException(
          'Login failed. Please check your email and password and try again.',
        );
      } else {
        throw AuthException(e.message ?? 'Login failed');
      }
    } catch (e) {
      print('login: Unexpected error: $e');
      if (e is AuthException) {
        // Pass through AuthExceptions directly
        rethrow;
      }
      throw ServerException('Unexpected error during login: $e');
    }
  }

  @override
  Future<Unit> updateUser(UserModel user) async {
    try {
      print('updateUser: Starting for user id=${user.id}, email=${user.email}');
      final normalizedEmail = user.email.toLowerCase().trim();
      final collection =
          user is PatientModel
              ? 'patients'
              : user is MedecinModel
              ? 'medecins'
              : 'users';

      // Check if appointmentDuration has changed (for doctors)
      if (user is MedecinModel) {
        try {
          final existingDoctor =
              await firestore.collection('medecins').doc(user.id).get();
          if (existingDoctor.exists) {
            final existingData = existingDoctor.data();
            final existingDuration =
                existingData?['appointmentDuration'] as int? ?? 30;

            // If duration has changed, we'll need to update appointments
            if (existingDuration != user.appointmentDuration) {
              print(
                'updateUser: Detected change in appointmentDuration from $existingDuration to ${user.appointmentDuration}',
              );

              // Update only the changed fields using .update() to preserve existing data
              Map<String, dynamic> updateData = {
                'name': user.name,
                'lastName': user.lastName,
                'email': normalizedEmail,
                'gender': user.gender,
                'phoneNumber': user.phoneNumber,
                'appointmentDuration': user.appointmentDuration,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              // Add optional fields only if they exist in the user object
              if (user.dateOfBirth != null) {
                updateData['dateOfBirth'] = user.dateOfBirth;
              }
              if (user.speciality != null) {
                updateData['speciality'] = user.speciality;
              }
              if (user.numLicence != null) {
                updateData['numLicence'] = user.numLicence;
              }
              if (user is MedecinModel) {
                final medecinUser = user as MedecinModel;
                if (medecinUser.education != null) {
                  updateData['education'] = medecinUser.education;
                }
                if (medecinUser.experience != null) {
                  updateData['experience'] = medecinUser.experience;
                }
                if (medecinUser.consultationFee != null) {
                  updateData['consultationFee'] = medecinUser.consultationFee;
                }
                if (medecinUser.address != null) {
                  updateData['address'] = medecinUser.address;
                }
                if (medecinUser.location != null) {
                  updateData['location'] = medecinUser.location;
                }
              }

              print(
                'updateUser: Updating doctor record with new duration using .update()',
              );
              await firestore
                  .collection(collection)
                  .doc(user.id)
                  .update(updateData);

              // Then update future appointments
              print('updateUser: Updating future appointments');
              await _updateFutureAppointmentsEndTime(
                user.id!,
                user.appointmentDuration,
              );

              // Get the updated document to cache locally
              final updatedDoc =
                  await firestore.collection(collection).doc(user.id).get();
              if (updatedDoc.exists) {
                final updatedUser = MedecinModel.fromJson(updatedDoc.data()!);
                await localDataSource.cacheUser(updatedUser);
              }

              print('updateUser: Completed with appointment updates');
              return unit;
            }
          }
        } catch (e) {
          print('updateUser: Error checking appointment duration: $e');
          // Continue with normal update flow if this part fails
        }
      }

      // Normal update flow - Use .update() instead of .set() to preserve existing data
      Map<String, dynamic> updateData = {
        'name': user.name,
        'lastName': user.lastName,
        'email': normalizedEmail,
        'gender': user.gender,
        'phoneNumber': user.phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields only if they exist in the user object
      if (user.dateOfBirth != null) {
        updateData['dateOfBirth'] = user.dateOfBirth;
      }

      // Add patient-specific fields
      if (user is PatientModel) {
        final patientUser = user as PatientModel;
        if (patientUser.antecedent != null) {
          updateData['antecedent'] = patientUser.antecedent;
        }
        if (patientUser.bloodType != null) {
          updateData['bloodType'] = patientUser.bloodType;
        }
        if (patientUser.height != null) {
          updateData['height'] = patientUser.height;
        }
        if (patientUser.weight != null) {
          updateData['weight'] = patientUser.weight;
        }
        if (patientUser.allergies != null) {
          updateData['allergies'] = patientUser.allergies;
        }
        if (patientUser.chronicDiseases != null) {
          updateData['chronicDiseases'] = patientUser.chronicDiseases;
        }
        if (patientUser.emergencyContact != null) {
          updateData['emergencyContact'] = patientUser.emergencyContact;
        }
        if (patientUser.address != null) {
          updateData['address'] = patientUser.address;
        }
        if (patientUser.location != null) {
          updateData['location'] = patientUser.location;
        }
      }

      // Add doctor-specific fields
      if (user is MedecinModel) {
        final medecinUser = user as MedecinModel;
        if (medecinUser.speciality != null) {
          updateData['speciality'] = medecinUser.speciality;
        }
        if (medecinUser.numLicence != null) {
          updateData['numLicence'] = medecinUser.numLicence;
        }
        if (medecinUser.appointmentDuration != null) {
          updateData['appointmentDuration'] = medecinUser.appointmentDuration;
        }
        if (medecinUser.education != null) {
          updateData['education'] = medecinUser.education;
        }
        if (medecinUser.experience != null) {
          updateData['experience'] = medecinUser.experience;
        }
        if (medecinUser.consultationFee != null) {
          updateData['consultationFee'] = medecinUser.consultationFee;
        }
        if (medecinUser.address != null) {
          updateData['address'] = medecinUser.address;
        }
        if (medecinUser.location != null) {
          updateData['location'] = medecinUser.location;
        }
      }

      // Only update verification-related fields if they are provided
      if (user.verificationCode != null) {
        updateData['verificationCode'] = user.verificationCode;
      }
      if (user.validationCodeExpiresAt != null) {
        updateData['validationCodeExpiresAt'] = user.validationCodeExpiresAt;
      }
      if (user.accountStatus != null) {
        updateData['accountStatus'] = user.accountStatus;
      }

      print(
        'updateUser: Updating Firestore in collection=$collection, doc=${user.id} using .update()',
      );
      print('updateUser: Update data keys: ${updateData.keys.toList()}');

      await firestore.collection(collection).doc(user.id).update(updateData);

      // Get the updated document to cache locally with all preserved data
      final updatedDoc =
          await firestore.collection(collection).doc(user.id).get();
      if (updatedDoc.exists) {
        UserModel updatedUser;
        if (collection == 'patients') {
          updatedUser = PatientModel.fromJson(updatedDoc.data()!);
        } else if (collection == 'medecins') {
          updatedUser = MedecinModel.fromJson(updatedDoc.data()!);
        } else {
          updatedUser = UserModel.fromJson(updatedDoc.data()!);
        }

        print('updateUser: Caching updated user locally');
        await localDataSource.cacheUser(updatedUser);
      }

      print('updateUser: Completed successfully');
      return unit;
    } on FirebaseException catch (e) {
      print('updateUser: FirebaseException: ${e.message}');
      throw ServerException(e.message ?? 'Failed to update user');
    } catch (e) {
      print('updateUser: Unexpected error: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Unit> sendVerificationCode({
    required String email,
    required VerificationCodeType codeType,
  }) async {
    try {
      print(
        'sendVerificationCode: Starting for email=$email, codeType=$codeType',
      );
      final normalizedEmail = email.toLowerCase().trim();
      print('sendVerificationCode: Normalized email=$normalizedEmail');

      // Step 1: Define the collections to search for the user
      final collections = ['patients', 'medecins', 'users'];
      String? collectionName;
      String? userId;

      // Step 2: Search for the user by email in each collection
      print('sendVerificationCode: Searching for user in collections');
      for (var collection in collections) {
        print(
          'sendVerificationCode: Querying collection=$collection for email=$normalizedEmail',
        );
        final query =
            await firestore
                .collection(collection)
                .where('email', isEqualTo: normalizedEmail)
                .get();
        print(
          'sendVerificationCode: Query result for $collection: ${query.docs.length} docs found',
        );
        if (query.docs.isNotEmpty) {
          collectionName = collection;
          userId = query.docs.first.id;
          print(
            'sendVerificationCode: User found in collection=$collectionName, userId=$userId',
          );
          print(
            'sendVerificationCode: Document data=${query.docs.first.data()}',
          );
          break;
        } else {
          print(
            'sendVerificationCode: No documents found in $collection for email=$normalizedEmail',
          );
          // Fallback: Check all documents for case-insensitive match
          final allDocs = await firestore.collection(collection).get();
          print(
            'sendVerificationCode: Checking all documents in $collection for case-insensitive match',
          );
          for (var doc in allDocs.docs) {
            final data = doc.data();
            if (data['email'] != null &&
                data['email'].toString().toLowerCase().trim() ==
                    normalizedEmail) {
              collectionName = collection;
              userId = doc.id;
              print(
                'sendVerificationCode: User found with case-insensitive match in $collection, userId=$userId',
              );
              print('sendVerificationCode: Document data=$data');
              // Update email to normalized form
              await firestore.collection(collection).doc(userId).update({
                'email': normalizedEmail,
              });
              print('sendVerificationCode: Email updated to $normalizedEmail');
              break;
            }
          }
          if (collectionName != null) break;
        }
      }

      // Step 3: Check if user was found
      if (collectionName == null || userId == null) {
        print(
          'sendVerificationCode: Error - User not found for email=$normalizedEmail',
        );
        for (var collection in collections) {
          final allDocs = await firestore.collection(collection).get();
          print(
            'sendVerificationCode: All documents in $collection: ${allDocs.docs.length}',
          );
          for (var doc in allDocs.docs) {
            print(
              'sendVerificationCode: Doc in $collection: id=${doc.id}, data=${doc.data()}',
            );
          }
        }
        throw AuthException('User not found');
      }

      // Step 4: Generate a 4-digit verification code
      final randomNumber = generateFourDigitNumber();
      print('sendVerificationCode: Generated verificationCode=$randomNumber');

      // Step 5: Update Firestore with verification code, expiration, and codeType
      print(
        'sendVerificationCode: Updating Firestore for collection=$collectionName, userId=$userId',
      );
      await firestore
          .collection(collectionName)
          .doc(userId)
          .update({
            'verificationCode': randomNumber,
            'validationCodeExpiresAt': DateTime.now().add(
              const Duration(minutes: 60),
            ),
            'codeType': codeType.toString().split('.').last,
          })
          .catchError((e) {
            print(
              'sendVerificationCode: Firestore update failed with error=$e',
            );
            throw FirebaseException(
              plugin: 'firestore',
              message: 'Failed to update verification code: $e',
            );
          });
      print('sendVerificationCode: Firestore updated successfully');

      // Step 6: Send the verification email
      print(
        'sendVerificationCode: Sending email with subject=${getSubjectForCodeType(codeType)}',
      );
      await sendVerificationEmail(
        email: normalizedEmail,
        subject: getSubjectForCodeType(codeType),
        code: randomNumber,
      ).catchError((e) {
        print('sendVerificationCode: Email sending failed with error=$e');
        throw ServerException('Failed to send verification email: $e');
      });
      print('sendVerificationCode: Email sent successfully');

      // Step 7: Return success
      print('sendVerificationCode: Completed successfully');
      return unit;
    } on FirebaseException catch (e) {
      print('sendVerificationCode: FirebaseException caught: ${e.message}');
      throw ServerException(e.message ?? 'Failed to send verification code');
    } catch (e) {
      print('sendVerificationCode: Unexpected error caught: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Unit> verifyCode({
    required String email,
    required int verificationCode,
    required VerificationCodeType codeType,
  }) async {
    try {
      print(
        'verifyCode: Starting for email=$email, code=$verificationCode, codeType=$codeType',
      );
      final normalizedEmail = email.toLowerCase().trim();
      final collections = ['patients', 'medecins', 'users'];
      String? collectionName;
      String? userId;
      dynamic userData;
      for (var collection in collections) {
        print(
          'verifyCode: Querying collection=$collection for email=$normalizedEmail',
        );
        final query =
            await firestore
                .collection(collection)
                .where('email', isEqualTo: normalizedEmail)
                .get();
        print(
          'verifyCode: Query result for $collection: ${query.docs.length} docs found',
        );
        if (query.docs.isNotEmpty) {
          collectionName = collection;
          userId = query.docs.first.id;
          userData = query.docs.first.data();
          print(
            'verifyCode: User found in collection=$collectionName, userId=$userId',
          );
          break;
        }
      }
      if (collectionName == null || userId == null) {
        print('verifyCode: Error - User not found for email=$normalizedEmail');
        throw AuthException('User not found');
      }
      if (userData['verificationCode'] != verificationCode) {
        print(
          'verifyCode: Error - Invalid verification code: expected=${userData['verificationCode']}, provided=$verificationCode',
        );
        throw AuthException('Invalid verification code');
      }
      if (userData['validationCodeExpiresAt']?.toDate().isBefore(
            DateTime.now(),
          ) ??
          true) {
        print('verifyCode: Error - Verification code expired');
        throw AuthException('Verification code expired');
      }
      if (userData['codeType'] != codeType.toString().split('.').last) {
        print(
          'verifyCode: Error - Invalid code type: expected=${userData['codeType']}, provided=${codeType.toString().split('.').last}',
        );
        throw AuthException('Invalid code type');
      }
      if (codeType == VerificationCodeType.activationDeCompte ||
          codeType == VerificationCodeType.compteActive) {
        print('verifyCode: Updating account status to active');
        await firestore.collection(collectionName).doc(userId).update({
          'accountStatus': true,
          'verificationCode': null,
          'validationCodeExpiresAt': null,
          'codeType': null,
        });
      }
      print('verifyCode: Completed successfully');
      return unit;
    } on FirebaseException catch (e) {
      print('verifyCode: FirebaseException: ${e.message}');
      throw ServerException(e.message ?? 'Failed to verify code');
    } catch (e) {
      print('verifyCode: Unexpected error: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Unit> changePassword({
    required String email,
    required String newPassword,
    required int verificationCode,
  }) async {
    try {
      print(
        'changePassword: Starting for email=$email, verificationCode=$verificationCode',
      );

      // Call our new direct password reset API endpoint
      final response = await http.post(
        Uri.parse('$emailServiceUrl/resetPasswordDirect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'newPassword': newPassword,
          'verificationCode': verificationCode,
        }),
      );

      print('changePassword: API response status=${response.statusCode}');

      if (response.statusCode == 200) {
        print('changePassword: Password reset successful');
        return unit;
      } else {
        // Parse the error message from the API response
        Map<String, dynamic> responseData = {};
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          print('changePassword: Error parsing response body: $e');
        }

        final errorMessage =
            responseData['message'] ?? 'Failed to reset password';
        print('changePassword: Error from API: $errorMessage');
        throw AuthException(errorMessage);
      }
    } catch (e) {
      print('changePassword: Unexpected error: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw ServerException('Unexpected error: $e');
    }
  }

  // Helper method to update future appointments' endTime when a doctor's appointmentDuration changes
  Future<void> _updateFutureAppointmentsEndTime(
    String doctorId,
    int appointmentDuration,
  ) async {
    try {
      print(
        '_updateFutureAppointmentsEndTime: Starting for doctorId=$doctorId with duration=$appointmentDuration',
      );

      // Get current date/time
      final now = DateTime.now();

      // Query all future appointments for this doctor with status "pending" or "accepted"
      final appointmentsQuery =
          await firestore
              .collection('rendez_vous')
              .where('doctorId', isEqualTo: doctorId)
              .where('startTime', isGreaterThanOrEqualTo: now.toIso8601String())
              .get();

      print(
        '_updateFutureAppointmentsEndTime: Found ${appointmentsQuery.docs.length} future appointments',
      );

      // Update each appointment's endTime
      for (final doc in appointmentsQuery.docs) {
        try {
          // Parse the startTime
          DateTime startTime;
          if (doc.data()['startTime'] is String) {
            startTime = DateTime.parse(doc.data()['startTime'] as String);
          } else if (doc.data()['startTime'] is Timestamp) {
            startTime = (doc.data()['startTime'] as Timestamp).toDate();
          } else {
            print(
              '_updateFutureAppointmentsEndTime: Skipping appointment with invalid startTime format',
            );
            continue;
          }

          // Calculate new endTime
          final endTime = startTime.add(Duration(minutes: appointmentDuration));

          // Update the appointment
          await firestore.collection('rendez_vous').doc(doc.id).update({
            'endTime': endTime.toIso8601String(),
          });

          print(
            '_updateFutureAppointmentsEndTime: Updated appointment ${doc.id}',
          );
        } catch (e) {
          print(
            '_updateFutureAppointmentsEndTime: Error updating appointment ${doc.id}: $e',
          );
          // Continue with other appointments even if one fails
          continue;
        }
      }

      print('_updateFutureAppointmentsEndTime: Completed');
    } catch (e) {
      print('_updateFutureAppointmentsEndTime: Error: $e');
      // Don't throw exception, as this is an enhancement, not a critical operation
    }
  }

  // Helper method to safely update FCM token and location without overwriting documents
  Future<void> updateUserTokenAndLocation({
    required String userId,
    String? fcmToken,
    Map<String, dynamic>? location,
    Map<String, dynamic>? address,
  }) async {
    try {
      print('updateUserTokenAndLocation: Starting for userId=$userId');

      // Find which collection the user is in
      String? collection;
      final collections = ['patients', 'medecins'];

      for (var coll in collections) {
        final doc = await firestore.collection(coll).doc(userId).get();
        if (doc.exists) {
          collection = coll;
          break;
        }
      }

      if (collection == null) {
        print('updateUserTokenAndLocation: User not found in any collection');
        return;
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fcmToken != null && fcmToken.isNotEmpty) {
        updateData['fcmToken'] = fcmToken;
        print('updateUserTokenAndLocation: Adding FCM token to update');
      }

      if (location != null) {
        updateData['location'] = location;
        print('updateUserTokenAndLocation: Adding location to update');
      }

      if (address != null) {
        updateData['address'] = address;
        print('updateUserTokenAndLocation: Adding address to update');
      }

      // Update the main collection
      await firestore.collection(collection).doc(userId).update(updateData);
      print('updateUserTokenAndLocation: Updated $collection collection');

      // Also update the users collection for notifications if FCM token is provided
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await firestore.collection('users').doc(userId).update({
          'fcmToken': fcmToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(
          'updateUserTokenAndLocation: Updated users collection for notifications',
        );
      }

      print('updateUserTokenAndLocation: Completed successfully');
    } catch (e) {
      print('updateUserTokenAndLocation: Error: $e');
      // Don't throw exception as this is often a background operation
    }
  }

  @override
  Future<Unit> deleteAccount({
    required String userId,
    required String password,
  }) async {
    try {
      print('deleteAccount: Starting for userId=$userId');

      // Get current Firebase user
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw AuthException('User not authenticated or user ID mismatch');
      }

      // Re-authenticate user with password before deletion
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);
      print('deleteAccount: User re-authenticated successfully');

      // Get user data to determine role and collection
      final userDoc = await firestore.collection('users').doc(userId).get();
      String? userRole;
      if (userDoc.exists) {
        userRole = userDoc.data()?['role'] as String?;
      }

      // Delete user data from Firestore collections
      final batch = firestore.batch();

      // Delete from main collection (patients or medecins)
      if (userRole == 'patient') {
        batch.delete(firestore.collection('patients').doc(userId));
      } else if (userRole == 'medecin') {
        batch.delete(firestore.collection('medecins').doc(userId));
      }

      // Delete from users collection
      batch.delete(firestore.collection('users').doc(userId));

      // Delete related data
      // Delete notifications
      final notificationsQuery =
          await firestore
              .collection('notifications')
              .where('recipientId', isEqualTo: userId)
              .get();
      for (final doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
      }

      final sentNotificationsQuery =
          await firestore
              .collection('notifications')
              .where('senderId', isEqualTo: userId)
              .get();
      for (final doc in sentNotificationsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete appointments
      final appointmentsQuery =
          await firestore
              .collection('rendez_vous')
              .where('patientId', isEqualTo: userId)
              .get();
      for (final doc in appointmentsQuery.docs) {
        batch.delete(doc.reference);
      }

      final doctorAppointmentsQuery =
          await firestore
              .collection('rendez_vous')
              .where('doctorId', isEqualTo: userId)
              .get();
      for (final doc in doctorAppointmentsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete conversations
      final conversationsQuery =
          await firestore
              .collection('conversations')
              .where('participants', arrayContains: userId)
              .get();
      for (final doc in conversationsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete prescriptions
      final prescriptionsQuery =
          await firestore
              .collection('prescriptions')
              .where('patientId', isEqualTo: userId)
              .get();
      for (final doc in prescriptionsQuery.docs) {
        batch.delete(doc.reference);
      }

      final doctorPrescriptionsQuery =
          await firestore
              .collection('prescriptions')
              .where('doctorId', isEqualTo: userId)
              .get();
      for (final doc in doctorPrescriptionsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete ratings
      final ratingsQuery =
          await firestore
              .collection('ratings')
              .where('patientId', isEqualTo: userId)
              .get();
      for (final doc in ratingsQuery.docs) {
        batch.delete(doc.reference);
      }

      final doctorRatingsQuery =
          await firestore
              .collection('ratings')
              .where('doctorId', isEqualTo: userId)
              .get();
      for (final doc in doctorRatingsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete medical files if patient
      if (userRole == 'patient') {
        final medicalFilesQuery =
            await firestore
                .collection('dossier_medical')
                .where('patientId', isEqualTo: userId)
                .get();
        for (final doc in medicalFilesQuery.docs) {
          batch.delete(doc.reference);
        }
      }

      // Commit all deletions
      await batch.commit();
      print('deleteAccount: Firestore data deleted successfully');

      // Clear local data
      await localDataSource.signOut();
      print('deleteAccount: Local data cleared');

      // Delete Firebase Auth user (this must be done last)
      await currentUser.delete();
      print('deleteAccount: Firebase Auth user deleted successfully');

      return unit;
    } on FirebaseAuthException catch (e) {
      print('deleteAccount: FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'wrong-password') {
        throw AuthException('Incorrect password provided');
      } else if (e.code == 'requires-recent-login') {
        throw AuthException('Please log in again before deleting your account');
      } else {
        throw AuthException(e.message ?? 'Failed to delete account');
      }
    } catch (e) {
      print('deleteAccount: Unexpected error: $e');
      throw ServerException('Failed to delete account: $e');
    }
  }
}
