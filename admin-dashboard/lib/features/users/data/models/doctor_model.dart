import '../../domain/entities/doctor_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel extends DoctorEntity {
  const DoctorModel({
    super.id,
    required super.fullName,
    required super.email,
    super.dateOfBirth,
    super.age,
    super.gender,
    super.phoneNumber,
    super.address,
    super.speciality,
    super.numLicence,
    required super.experienceYears,
    required super.educationSummary,
    required super.appointmentDuration,
    super.consultationFee,
    super.accountStatus = true,
    super.lastLogin,
    super.createdAt,
  });

  factory DoctorModel.fromEntity(DoctorEntity entity) {
    return DoctorModel(
      id: entity.id,
      fullName: entity.fullName,
      email: entity.email,
      dateOfBirth: entity.dateOfBirth,
      age: entity.age,
      gender: entity.gender,
      phoneNumber: entity.phoneNumber,
      address: entity.address,
      speciality: entity.speciality,
      numLicence: entity.numLicence,
      experienceYears: entity.experienceYears,
      educationSummary: entity.educationSummary,
      appointmentDuration: entity.appointmentDuration,
      consultationFee: entity.consultationFee,
      accountStatus: entity.accountStatus,
      lastLogin: entity.lastLogin,
      createdAt: entity.createdAt,
    );
  }

  factory DoctorModel.fromFirestore(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String?,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: _parseDateTime(json['dateOfBirth']),
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      speciality: json['speciality'] as String?,
      numLicence: json['numLicence']?.toString() ?? '',
      experienceYears: json['experienceYears']?.toString() ?? 'N/A',
      educationSummary: json['educationSummary']?.toString() ?? 'N/A',
      appointmentDuration: _parseInt(json['appointmentDuration']) ?? 30,
      consultationFee: _parseDouble(json['consultationFee']),
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String && value.isNotEmpty) {
      try {
        return int.parse(value);
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
      'speciality': speciality,
      'numLicence': numLicence,
      'experienceYears': experienceYears,
      'educationSummary': educationSummary,
      'appointmentDuration': appointmentDuration,
      'consultationFee': consultationFee,
      'accountStatus': accountStatus,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  DoctorEntity toEntity() {
    return DoctorEntity(
      id: id,
      fullName: fullName,
      email: email,
      dateOfBirth: dateOfBirth,
      age: age,
      gender: gender,
      phoneNumber: phoneNumber,
      address: address,
      speciality: speciality,
      numLicence: numLicence,
      experienceYears: experienceYears,
      educationSummary: educationSummary,
      appointmentDuration: appointmentDuration,
      consultationFee: consultationFee,
      accountStatus: accountStatus,
      lastLogin: lastLogin,
      createdAt: createdAt,
    );
  }
}
