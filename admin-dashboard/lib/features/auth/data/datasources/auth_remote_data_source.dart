import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      print('Admin login attempt for email: $email');

      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('User not found');
      }

      print('Firebase auth successful for user: ${user.uid}');

      // Check if user exists in users collection first
      DocumentSnapshot? userDoc;
      try {
        userDoc = await firestore.collection('users').doc(user.uid).get();
        print('Users collection check: exists=${userDoc.exists}');
      } catch (e) {
        print('Error checking users collection: $e');
      }

      Map<String, dynamic>? userData;

      if (userDoc != null && userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>?;
        print('User data from users collection: $userData');
      } else {
        // If not in users collection, create admin user
        print('User not found in users collection, creating admin user');
        userData = {
          'id': user.uid,
          'name': 'Admin',
          'lastName': 'User',
          'email': user.email!,
          'role': UserEntity.ROLE_ADMIN,
          'phoneNumber': '',
          'isOnline': true,
          'lastLogin': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Create the admin user document
        await firestore.collection('users').doc(user.uid).set(userData);
        print('Created admin user in users collection');
      }

      // Ensure this is an admin or create admin role
      if (userData!['role'] != UserEntity.ROLE_ADMIN) {
        // Update user to admin role if they're logging into admin dashboard
        await firestore.collection('users').doc(user.uid).update({
          'role': UserEntity.ROLE_ADMIN,
        });
        userData['role'] = UserEntity.ROLE_ADMIN;
        print('Updated user role to admin');
      }

      // Update the last login time
      await firestore.collection('users').doc(user.uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
        'isOnline': true,
      });

      print('Login successful for admin user');

      return UserModel(
        id: user.uid,
        name: userData['name'] ?? 'Admin',
        email: user.email!,
        phoneNumber: userData['phoneNumber'] ?? '',
        role: userData['role'] ?? UserEntity.ROLE_ADMIN,
        isOnline: true,
        lastLogin: DateTime.now(),
        createdAt:
            userData['createdAt'] != null
                ? DateTime.parse(userData['createdAt'])
                : DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw AuthException('No user found for that email');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Wrong password provided');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Invalid email address');
      } else if (e.code == 'user-disabled') {
        throw AuthException('User account has been disabled');
      } else {
        throw AuthException(e.message ?? 'Authentication error');
      }
    } catch (e) {
      print('Login error: $e');
      if (e is AuthException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
        });
      }
      await firebaseAuth.signOut();
    } catch (e) {
      print('Logout error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }

      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data()!;

      return UserModel(
        id: user.uid,
        name: userData['name'] ?? 'Admin User',
        email: user.email!,
        phoneNumber: userData['phoneNumber'] ?? '',
        role: userData['role'] ?? UserEntity.ROLE_ADMIN,
        isOnline: userData['isOnline'] ?? false,
        lastLogin:
            userData['lastLogin'] != null
                ? DateTime.parse(userData['lastLogin'])
                : null,
        createdAt:
            userData['createdAt'] != null
                ? DateTime.parse(userData['createdAt'])
                : null,
      );
    } catch (e) {
      print('Get current user error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return false;
      }

      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data()!;

      // Accept any user for admin dashboard (they'll be promoted to admin)
      return userData['role'] == UserEntity.ROLE_ADMIN ||
          userData['role'] == 'medecin' ||
          userData['role'] == 'patient';
    } catch (e) {
      print('Is logged in check error: $e');
      return false;
    }
  }
}
