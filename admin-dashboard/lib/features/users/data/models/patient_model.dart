import '../../domain/entities/patient_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel extends PatientEntity {
  const PatientModel({
    super.id,
    required super.fullName,
    required super.email,
    super.dateOfBirth,
    super.age,
    super.gender,
    super.phoneNumber,
    super.address,
    super.bloodType,
    super.height,
    super.weight,
    super.allergies,
    super.chronicDiseases,
    super.antecedent,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.accountStatus = true,
    super.lastLogin,
    super.createdAt,
  });

  factory PatientModel.fromEntity(PatientEntity entity) {
    return PatientModel(
      id: entity.id,
      fullName: entity.fullName,
      email: entity.email,
      dateOfBirth: entity.dateOfBirth,
      age: entity.age,
      gender: entity.gender,
      phoneNumber: entity.phoneNumber,
      address: entity.address,
      bloodType: entity.bloodType,
      height: entity.height,
      weight: entity.weight,
      allergies: entity.allergies,
      chronicDiseases: entity.chronicDiseases,
      antecedent: entity.antecedent,
      emergencyContactName: entity.emergencyContactName,
      emergencyContactPhone: entity.emergencyContactPhone,
      accountStatus: entity.accountStatus,
      lastLogin: entity.lastLogin,
      createdAt: entity.createdAt,
    );
  }

  factory PatientModel.fromFirestore(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String?,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: _parseDateTime(json['dateOfBirth']),
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      bloodType: json['bloodType'] as String?,
      height: _parseDouble(json['height']),
      weight: _parseDouble(json['weight']),
      allergies: _parseStringList(json['allergies']),
      chronicDiseases: _parseStringList(json['chronicDiseases']),
      antecedent: json['antecedent'] as String?,
      emergencyContactName: _parseEmergencyContactName(json['emergencyContact']),
      emergencyContactPhone: _parseEmergencyContactPhone(json['emergencyContact']),
      accountStatus: _parseBool(json['accountStatus']) ?? true,
      lastLogin: _parseDateTime(json['updatedAt']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  // Helper methods to safely parse different data types
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }

  static String? _parseEmergencyContactName(dynamic emergencyContact) {
    if (emergencyContact is Map<String, dynamic>) {
      return emergencyContact['name']?.toString();
    }
    return null;
  }

  static String? _parseEmergencyContactPhone(dynamic emergencyContact) {
    if (emergencyContact is Map<String, dynamic>) {
      return emergencyContact['phoneNumber']?.toString();
    }
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'address': address,
      'bloodType': bloodType,
      'height': height,
      'weight': weight,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'antecedent': antecedent,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'accountStatus': accountStatus,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  PatientEntity toEntity() {
    return PatientEntity(
      id: id,
      fullName: fullName,
      email: email,
      dateOfBirth: dateOfBirth,
      age: age,
      gender: gender,
      phoneNumber: phoneNumber,
      address: address,
      bloodType: bloodType,
      height: height,
      weight: weight,
      allergies: allergies,
      chronicDiseases: chronicDiseases,
      antecedent: antecedent,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      accountStatus: accountStatus,
      lastLogin: lastLogin,
      createdAt: createdAt,
    );
  }
}
