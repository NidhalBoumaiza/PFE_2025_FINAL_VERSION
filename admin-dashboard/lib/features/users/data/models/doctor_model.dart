import '../../domain/entities/doctor_entity.dart';

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
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'] as String)
              : null,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      speciality: json['speciality'] as String?,
      numLicence: json['numLicence'] as String?,
      experienceYears: json['experienceYears'] as String? ?? 'N/A',
      educationSummary: json['educationSummary'] as String? ?? 'N/A',
      appointmentDuration: json['appointmentDuration'] as int? ?? 30,
      consultationFee: (json['consultationFee'] as num?)?.toDouble(),
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
