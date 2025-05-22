import '../../domain/entities/medecin_entity.dart';
import './user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedecinModel extends UserModel {
  final String speciality;
  final String numLicence;
  final int appointmentDuration; // Duration in minutes for each appointment
  final List<Map<String, String>>? education;
  final List<Map<String, String>>? experience;
  final double? consultationFee;

  MedecinModel({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    bool? accountStatus,
    int? verificationCode,
    required this.speciality,
    required this.numLicence,
    this.appointmentDuration = 30, // Default 30 minutes
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

  factory MedecinModel.fromJson(Map<String, dynamic> json) {
    // Handle potential null or wrong types for each field
    final String id = json['id'] is String ? json['id'] as String : '';
    final String name = json['name'] is String ? json['name'] as String : '';
    final String lastName =
        json['lastName'] is String ? json['lastName'] as String : '';
    final String email = json['email'] is String ? json['email'] as String : '';
    final String role =
        json['role'] is String ? json['role'] as String : 'medecin';
    final String gender =
        json['gender'] is String ? json['gender'] as String : 'Homme';
    final String phoneNumber =
        json['phoneNumber'] is String ? json['phoneNumber'] as String : '';
    final String speciality =
        json['speciality'] is String
            ? json['speciality'] as String
            : 'Généraliste';
    final String numLicence =
        json['numLicence'] is String ? json['numLicence'] as String : '';

    // Handle appointment duration with robust type checking
    int appointmentDuration = 30; // Default value
    if (json['appointmentDuration'] is int) {
      appointmentDuration = json['appointmentDuration'] as int;
    } else if (json['appointmentDuration'] is String &&
        (json['appointmentDuration'] as String).isNotEmpty) {
      try {
        appointmentDuration = int.parse(json['appointmentDuration'] as String);
      } catch (_) {
        // Keep default value if parsing fails
      }
    }

    // Handle nullable fields with proper type checking
    DateTime? dateOfBirth;
    if (json['dateOfBirth'] is String &&
        (json['dateOfBirth'] as String).isNotEmpty) {
      try {
        dateOfBirth = DateTime.parse(json['dateOfBirth'] as String);
      } catch (_) {
        dateOfBirth = null;
      }
    }

    bool? accountStatus;
    if (json['accountStatus'] is bool) {
      accountStatus = json['accountStatus'] as bool;
    } else if (json['accountStatus'] is String) {
      accountStatus = (json['accountStatus'] as String).toLowerCase() == 'true';
    } else {
      accountStatus = false;
    }

    int? verificationCode;
    if (json['verificationCode'] is int) {
      verificationCode = json['verificationCode'] as int;
    } else if (json['verificationCode'] is String &&
        (json['verificationCode'] as String).isNotEmpty) {
      try {
        verificationCode = int.parse(json['verificationCode'] as String);
      } catch (_) {
        verificationCode = null;
      }
    }

    DateTime? validationCodeExpiresAt;
    if (json['validationCodeExpiresAt'] is String &&
        (json['validationCodeExpiresAt'] as String).isNotEmpty) {
      try {
        validationCodeExpiresAt = DateTime.parse(
          json['validationCodeExpiresAt'] as String,
        );
      } catch (_) {
        validationCodeExpiresAt = null;
      }
    }

    String? fcmToken;
    if (json['fcmToken'] is String) {
      fcmToken = json['fcmToken'] as String;
    }

    // Handle address and location
    Map<String, String?>? address;
    if (json['address'] is Map) {
      address = Map<String, String?>.from(
        (json['address'] as Map).map(
          (key, value) => MapEntry(key.toString(), value?.toString()),
        ),
      );
    }

    Map<String, dynamic>? location;
    if (json['location'] is Map) {
      location = Map<String, dynamic>.from(json['location'] as Map);
    }

    // Handle education
    List<Map<String, String>>? education;
    if (json['education'] is List) {
      education =
          (json['education'] as List).where((item) => item is Map).map((item) {
            return Map<String, String>.from(
              (item as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            );
          }).toList();
    }

    // Handle experience
    List<Map<String, String>>? experience;
    if (json['experience'] is List) {
      experience =
          (json['experience'] as List).where((item) => item is Map).map((item) {
            return Map<String, String>.from(
              (item as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            );
          }).toList();
    }

    // Handle consultation fee
    double? consultationFee;
    if (json['consultationFee'] is double) {
      consultationFee = json['consultationFee'] as double;
    } else if (json['consultationFee'] is int) {
      consultationFee = (json['consultationFee'] as int).toDouble();
    } else if (json['consultationFee'] is String &&
        (json['consultationFee'] as String).isNotEmpty) {
      try {
        consultationFee = double.parse(json['consultationFee'] as String);
      } catch (_) {
        consultationFee = null;
      }
    }

    return MedecinModel(
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
      accountStatus: accountStatus,
      verificationCode: verificationCode,
      validationCodeExpiresAt: validationCodeExpiresAt,
      fcmToken: fcmToken,
      appointmentDuration: appointmentDuration,
      address: address,
      location: location,
      education: education,
      experience: experience,
      consultationFee: consultationFee,
    );
  }

  /// Creates a valid MedecinModel from potentially corrupted document data
  /// This can help recover accounts when data is malformed
  static MedecinModel recoverFromCorruptDoc(
    Map<String, dynamic>? docData,
    String userId,
    String userEmail,
  ) {
    // Default values for required fields if missing or corrupted
    final Map<String, dynamic> safeData = {
      'id': userId,
      'name': '',
      'lastName': '',
      'email': userEmail,
      'role': 'medecin',
      'gender': 'Homme',
      'phoneNumber': '',
      'speciality': 'Généraliste',
      'numLicence': '',
      'appointmentDuration': 30,
      'accountStatus': true,
    };

    // Use existing data when available and valid
    if (docData != null) {
      if (docData['name'] is String) safeData['name'] = docData['name'];
      if (docData['lastName'] is String)
        safeData['lastName'] = docData['lastName'];
      if (docData['gender'] is String) safeData['gender'] = docData['gender'];
      if (docData['phoneNumber'] is String)
        safeData['phoneNumber'] = docData['phoneNumber'];
      if (docData['fcmToken'] is String)
        safeData['fcmToken'] = docData['fcmToken'];
      if (docData['speciality'] is String)
        safeData['speciality'] = docData['speciality'];
      if (docData['numLicence'] is String)
        safeData['numLicence'] = docData['numLicence'];

      // Handle address and location
      if (docData['address'] is Map) {
        safeData['address'] = docData['address'];
      }
      if (docData['location'] is Map) {
        safeData['location'] = docData['location'];
      }

      // Handle appointment duration safely
      if (docData['appointmentDuration'] is int) {
        safeData['appointmentDuration'] = docData['appointmentDuration'];
      } else if (docData['appointmentDuration'] is String &&
          (docData['appointmentDuration'] as String).isNotEmpty) {
        try {
          safeData['appointmentDuration'] = int.parse(
            docData['appointmentDuration'] as String,
          );
        } catch (_) {
          // Keep default value if parsing fails
        }
      }

      // Handle education
      if (docData['education'] is List) {
        safeData['education'] = docData['education'];
      }

      // Handle experience
      if (docData['experience'] is List) {
        safeData['experience'] = docData['experience'];
      }

      // Handle consultation fee
      if (docData['consultationFee'] is double ||
          docData['consultationFee'] is int) {
        safeData['consultationFee'] = docData['consultationFee'];
      } else if (docData['consultationFee'] is String &&
          (docData['consultationFee'] as String).isNotEmpty) {
        try {
          safeData['consultationFee'] = double.parse(
            docData['consultationFee'] as String,
          );
        } catch (_) {
          // Invalid format, don't add to safeData
        }
      }

      // Handle dateOfBirth properly
      if (docData['dateOfBirth'] is String &&
          (docData['dateOfBirth'] as String).isNotEmpty) {
        try {
          DateTime dateOfBirth = DateTime.parse(
            docData['dateOfBirth'] as String,
          );
          safeData['dateOfBirth'] = dateOfBirth.toIso8601String();
        } catch (_) {
          // Invalid date format, don't add to safeData
        }
      } else if (docData['dateOfBirth'] is Timestamp) {
        try {
          DateTime dateOfBirth = (docData['dateOfBirth'] as Timestamp).toDate();
          safeData['dateOfBirth'] = dateOfBirth.toIso8601String();
        } catch (_) {
          // Invalid timestamp, don't add to safeData
        }
      }
    }

    return MedecinModel.fromJson(safeData);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['speciality'] = speciality;
    data['numLicence'] = numLicence;
    data['appointmentDuration'] = appointmentDuration;

    if (education != null) {
      data['education'] = education;
    }
    if (experience != null) {
      data['experience'] = experience;
    }
    if (consultationFee != null) {
      data['consultationFee'] = consultationFee;
    }

    return data;
  }

  MedecinEntity toEntity() {
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
      address: address,
      location: location,
      education: education,
      experience: experience,
      consultationFee: consultationFee,
    );
  }

  @override
  MedecinModel copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    String? role,
    String? gender,
    String? phoneNumber,
    DateTime? dateOfBirth,
    bool? accountStatus,
    int? verificationCode,
    DateTime? validationCodeExpiresAt,
    String? speciality,
    String? numLicence,
    int? appointmentDuration,
    String? fcmToken,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    List<Map<String, String>>? education,
    List<Map<String, String>>? experience,
    double? consultationFee,
  }) {
    return MedecinModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      accountStatus: accountStatus ?? this.accountStatus,
      verificationCode: verificationCode ?? this.verificationCode,
      validationCodeExpiresAt:
          validationCodeExpiresAt ?? this.validationCodeExpiresAt,
      speciality: speciality ?? this.speciality,
      numLicence: numLicence ?? this.numLicence,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      fcmToken: fcmToken ?? this.fcmToken,
      address: address ?? this.address,
      location: location ?? this.location,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      consultationFee: consultationFee ?? this.consultationFee,
    );
  }
}
