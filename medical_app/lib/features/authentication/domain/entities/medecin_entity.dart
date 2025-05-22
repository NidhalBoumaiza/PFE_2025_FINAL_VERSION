import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';

class MedecinEntity extends UserEntity {
  final String? speciality;
  final String? numLicence;
  final int
  appointmentDuration; // Duration in minutes for each appointment (default 30 minutes)
  // Added fields for professional credentials and financial information
  final List<Map<String, String>>? education;
  final List<Map<String, String>>? experience;
  final double? consultationFee;

  MedecinEntity({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    this.speciality,
    this.numLicence = '',
    this.appointmentDuration = 30, // Default 30 minutes
    bool? accountStatus,
    int? verificationCode,
    DateTime? validationCodeExpiresAt,
    String? fcmToken,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    this.education,
    this.experience,
    this.consultationFee,
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
       );

  factory MedecinEntity.create({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    String? speciality,
    String? numLicence = '',
    int appointmentDuration = 30, // Default 30 minutes
    bool? accountStatus,
    int? verificationCode,
    DateTime? validationCodeExpiresAt,
    String? fcmToken,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    List<Map<String, String>>? education,
    List<Map<String, String>>? experience,
    double? consultationFee,
  }) {
    return MedecinEntity(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      role: role,
      gender: gender,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      speciality: speciality,
      numLicence: numLicence,
      appointmentDuration: appointmentDuration,
      accountStatus: accountStatus,
      verificationCode: verificationCode,
      validationCodeExpiresAt: validationCodeExpiresAt,
      fcmToken: fcmToken,
      address: address,
      location: location,
      education: education,
      experience: experience,
      consultationFee: consultationFee,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    speciality,
    numLicence,
    appointmentDuration,
    education,
    experience,
    consultationFee,
  ];
}
