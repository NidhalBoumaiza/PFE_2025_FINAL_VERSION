import 'package:equatable/equatable.dart';
import 'package:medical_app/features/dossier_medical/domain/entities/medical_file_entity.dart';
import 'user_entity.dart';

class PatientEntity extends UserEntity {
  final String antecedent;
  final String? bloodType;
  final double? height;
  final double? weight;
  final List<String>? allergies;
  final List<String>? chronicDiseases;
  final Map<String, String?>? emergencyContact;
  final List<MedicalFileEntity>? dossierFiles;

  PatientEntity({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    required this.antecedent,
    bool? accountStatus,
    int? verificationCode,
    DateTime? validationCodeExpiresAt,
    String? fcmToken,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? profilePictureUrl,
    this.bloodType,
    this.height,
    this.weight,
    this.allergies,
    this.chronicDiseases,
    this.emergencyContact,
    this.dossierFiles,
  }) : super(
         id: id,
         name: name,
         lastName: lastName,
         email: email,
         role: role,
         gender: gender,
         phoneNumber: phoneNumber,
         dateOfBirth: dateOfBirth,
         accountStatus: accountStatus,
         verificationCode: verificationCode,
         validationCodeExpiresAt: validationCodeExpiresAt,
         fcmToken: fcmToken,
         address: address,
         location: location,
         profilePictureUrl: profilePictureUrl,
       );

  factory PatientEntity.create({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    required String antecedent,
    bool? accountStatus,
    int? verificationCode,
    DateTime? validationCodeExpiresAt,
    String? fcmToken,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? profilePictureUrl,
    String? bloodType,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? chronicDiseases,
    Map<String, String?>? emergencyContact,
    List<MedicalFileEntity>? dossierFiles,
  }) {
    return PatientEntity(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      role: role,
      gender: gender,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      antecedent: antecedent,
      accountStatus: accountStatus,
      verificationCode: verificationCode,
      validationCodeExpiresAt: validationCodeExpiresAt,
      fcmToken: fcmToken,
      address: address,
      location: location,
      profilePictureUrl: profilePictureUrl,
      bloodType: bloodType,
      height: height,
      weight: weight,
      allergies: allergies,
      chronicDiseases: chronicDiseases,
      emergencyContact: emergencyContact,
      dossierFiles: dossierFiles,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    antecedent,
    bloodType,
    height,
    weight,
    allergies,
    chronicDiseases,
    emergencyContact,
    dossierFiles,
  ];
}
