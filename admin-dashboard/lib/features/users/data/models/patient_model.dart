import '../../domain/entities/patient_entity.dart';

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
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'] as String)
              : null,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      bloodType: json['bloodType'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      allergies:
          json['allergies'] != null
              ? List<String>.from(json['allergies'] as List)
              : null,
      chronicDiseases:
          json['chronicDiseases'] != null
              ? List<String>.from(json['chronicDiseases'] as List)
              : null,
      antecedent: json['antecedent'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      accountStatus: json['accountStatus'] as bool? ?? true,
      lastLogin:
          json['lastLogin'] != null
              ? DateTime.parse(json['lastLogin'] as String)
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
    );
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
