import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/features/dossier_medical/data/models/medical_file_model.dart';
import '../../domain/entities/patient_entity.dart';
import 'user_model.dart';

class PatientModel extends UserModel {
  final String antecedent;
  final String? bloodType;
  final double? height;
  final double? weight;
  final List<String>? allergies;
  final List<String>? chronicDiseases;
  final Map<String, String?>? emergencyContact;
  final List<MedicalFileModel>? dossierFiles;

  PatientModel({
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
    required this.antecedent,
    DateTime? validationCodeExpiresAt,
    String? fcmToken,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
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
  );

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] is String ? json['id'] as String : '';
    final String name = json['name'] is String ? json['name'] as String : '';
    final String lastName =
    json['lastName'] is String ? json['lastName'] as String : '';
    final String email = json['email'] is String ? json['email'] as String : '';
    final String role =
    json['role'] is String ? json['role'] as String : 'patient';
    final String gender =
    json['gender'] is String ? json['gender'] as String : 'Homme';
    final String phoneNumber =
    json['phoneNumber'] is String ? json['phoneNumber'] as String : '';
    final String antecedent =
    json['antecedent'] is String ? json['antecedent'] as String : '';

    DateTime? dateOfBirth;
    if (json['dateOfBirth'] is String &&
        (json['dateOfBirth'] as String).isNotEmpty) {
      try {
        dateOfBirth = DateTime.parse(json['dateOfBirth'] as String);
      } catch (_) {
        dateOfBirth = null;
      }
    } else if (json['dateOfBirth'] is Timestamp) {
      dateOfBirth = (json['dateOfBirth'] as Timestamp).toDate();
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
    } else if (json['validationCodeExpiresAt'] is Timestamp) {
      validationCodeExpiresAt = (json['validationCodeExpiresAt'] as Timestamp).toDate();
    }

    String? fcmToken;
    if (json['fcmToken'] is String) {
      fcmToken = json['fcmToken'] as String;
    }

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

    String? bloodType;
    if (json['bloodType'] is String) {
      bloodType = json['bloodType'] as String;
    }

    double? height;
    if (json['height'] is double) {
      height = json['height'] as double;
    } else if (json['height'] is int) {
      height = (json['height'] as int).toDouble();
    } else if (json['height'] is String &&
        (json['height'] as String).isNotEmpty) {
      try {
        height = double.parse(json['height'] as String);
      } catch (_) {
        height = null;
      }
    }

    double? weight;
    if (json['weight'] is double) {
      weight = json['weight'] as double;
    } else if (json['weight'] is int) {
      weight = (json['weight'] as int).toDouble();
    } else if (json['weight'] is String &&
        (json['weight'] as String).isNotEmpty) {
      try {
        weight = double.parse(json['weight'] as String);
      } catch (_) {
        weight = null;
      }
    }

    List<String>? allergies;
    if (json['allergies'] is List) {
      allergies =
          (json['allergies'] as List).map((item) => item.toString()).toList();
    }

    List<String>? chronicDiseases;
    if (json['chronicDiseases'] is List) {
      chronicDiseases =
          (json['chronicDiseases'] as List)
              .map((item) => item.toString())
              .toList();
    }

    Map<String, String?>? emergencyContact;
    if (json['emergencyContact'] is Map) {
      emergencyContact = Map<String, String?>.from(
        (json['emergencyContact'] as Map).map(
              (key, value) => MapEntry(key.toString(), value?.toString()),
        ),
      );
    }

    List<MedicalFileModel>? dossierFiles;
    if (json['dossierFiles'] is List) {
      dossierFiles = (json['dossierFiles'] as List)
          .map((file) => MedicalFileModel.fromJson(file as Map<String, dynamic>))
          .toList();
    }

    return PatientModel(
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
      bloodType: bloodType,
      height: height,
      weight: weight,
      allergies: allergies,
      chronicDiseases: chronicDiseases,
      emergencyContact: emergencyContact,
      dossierFiles: dossierFiles,
    );
  }

  static PatientModel recoverFromCorruptDoc(
      Map<String, dynamic>? docData,
      String userId,
      String userEmail,
      ) {
    final Map<String, dynamic> safeData = {
      'id': userId,
      'name': '',
      'lastName': '',
      'email': userEmail,
      'role': 'patient',
      'gender': 'Homme',
      'phoneNumber': '',
      'antecedent': '',
      'accountStatus': true,
    };

    if (docData != null) {
      if (docData['name'] is String) safeData['name'] = docData['name'];
      if (docData['lastName'] is String)
        safeData['lastName'] = docData['lastName'];
      if (docData['gender'] is String) safeData['gender'] = docData['gender'];
      if (docData['phoneNumber'] is String)
        safeData['phoneNumber'] = docData['phoneNumber'];
      if (docData['fcmToken'] is String)
        safeData['fcmToken'] = docData['fcmToken'];
      if (docData['antecedent'] is String)
        safeData['antecedent'] = docData['antecedent'];
      if (docData['address'] is Map) {
        safeData['address'] = docData['address'];
      }
      if (docData['location'] is Map) {
        safeData['location'] = docData['location'];
      }
      if (docData['bloodType'] is String) {
        safeData['bloodType'] = docData['bloodType'];
      }
      if (docData['height'] is double || docData['height'] is int) {
        safeData['height'] = docData['height'];
      } else if (docData['height'] is String &&
          (docData['height'] as String).isNotEmpty) {
        try {
          safeData['height'] = double.parse(docData['height'] as String);
        } catch (_) {}
      }
      if (docData['weight'] is double || docData['weight'] is int) {
        safeData['weight'] = docData['weight'];
      } else if (docData['weight'] is String &&
          (docData['weight'] as String).isNotEmpty) {
        try {
          safeData['weight'] = double.parse(docData['weight'] as String);
        } catch (_) {}
      }
      if (docData['allergies'] is List) {
        safeData['allergies'] = docData['allergies'];
      }
      if (docData['chronicDiseases'] is List) {
        safeData['chronicDiseases'] = docData['chronicDiseases'];
      }
      if (docData['emergencyContact'] is Map) {
        safeData['emergencyContact'] = docData['emergencyContact'];
      }
      if (docData['dossierFiles'] is List) {
        safeData['dossierFiles'] = docData['dossierFiles'];
      }
      if (docData['dateOfBirth'] is String &&
          (docData['dateOfBirth'] as String).isNotEmpty) {
        try {
          DateTime dateOfBirth = DateTime.parse(
            docData['dateOfBirth'] as String,
          );
          safeData['dateOfBirth'] = dateOfBirth.toIso8601String();
        } catch (_) {}
      } else if (docData['dateOfBirth'] is Timestamp) {
        try {
          DateTime dateOfBirth = (docData['dateOfBirth'] as Timestamp).toDate();
          safeData['dateOfBirth'] = dateOfBirth.toIso8601String();
        } catch (_) {}
      }
    }

    return PatientModel.fromJson(safeData);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['antecedent'] = antecedent;
    if (bloodType != null) {
      data['bloodType'] = bloodType;
    }
    if (height != null) {
      data['height'] = height;
    }
    if (weight != null) {
      data['weight'] = weight;
    }
    if (allergies != null) {
      data['allergies'] = allergies;
    }
    if (chronicDiseases != null) {
      data['chronicDiseases'] = chronicDiseases;
    }
    if (emergencyContact != null) {
      data['emergencyContact'] = emergencyContact;
    }
    if (dossierFiles != null) {
      data['dossierFiles'] = dossierFiles!.map((file) => file.toJson()).toList();
    }
    return data;
  }

  PatientEntity toEntity() {
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
      bloodType: bloodType,
      height: height,
      weight: weight,
      allergies: allergies,
      chronicDiseases: chronicDiseases,
      emergencyContact: emergencyContact,
      dossierFiles: dossierFiles?.map((file) => file.toEntity()).toList(),
    );
  }

  @override
  PatientModel copyWith({
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
    String? antecedent,
    String? fcmToken,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? bloodType,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? chronicDiseases,
    Map<String, String?>? emergencyContact,
    List<MedicalFileModel>? dossierFiles,
  }) {
    return PatientModel(
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
      antecedent: antecedent ?? this.antecedent,
      fcmToken: fcmToken ?? this.fcmToken,
      address: address ?? this.address,
      location: location ?? this.location,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      dossierFiles: dossierFiles ?? this.dossierFiles,
    );
  }
}