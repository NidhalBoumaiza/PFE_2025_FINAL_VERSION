import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/medecin_model.dart';

abstract class AuthLocalDataSource {
  /// Caches the user data locally.
  Future<Unit> cacheUser(UserModel user);

  /// Retrieves the cached user data.
  Future<UserModel> getUser();

  /// Clears cached user data and token (signs out locally).
  Future<Unit> signOut();

  /// Saves the authentication token.
  Future<Unit> saveToken(String token);

  /// Retrieves the authentication token.
  Future<String?> getToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  static const String USER_KEY = 'CACHED_USER';
  static const String TOKEN_KEY = 'TOKEN';

  @override
  Future<Unit> cacheUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await sharedPreferences.setString(USER_KEY, userJson);
    return unit;
  }

  @override
  Future<UserModel> getUser() async {
    final userJson = sharedPreferences.getString(USER_KEY);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        if (userMap.containsKey('antecedent')) {
          // It's a patient model
          return PatientModel.fromJson(userMap);
        } else if (userMap.containsKey('speciality') &&
            userMap.containsKey('numLicence')) {
          // It's a doctor model
          return MedecinModel.fromJson(userMap);
        } else {
          // It's a basic user model
          return UserModel.fromJson(userMap);
        }
      } catch (e) {
        throw EmptyCacheException('Failed to parse cached user data: $e');
      }
    } else {
      throw EmptyCacheException('No cached user data found');
    }
  }

  @override
  Future<Unit> signOut() async {
    await sharedPreferences.remove(USER_KEY);
    await sharedPreferences.remove(TOKEN_KEY);
    return unit;
  }

  @override
  Future<Unit> saveToken(String token) async {
    await sharedPreferences.setString(TOKEN_KEY, token);
    return unit;
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(TOKEN_KEY);
  }
}
