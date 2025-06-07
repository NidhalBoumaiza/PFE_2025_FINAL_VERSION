class PatientEntity {
  final String? id;
  final String fullName;
  final String email;
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender;
  final String? phoneNumber;
  final String? address;
  final String? bloodType;
  final double? height;
  final double? weight;
  final List<String>? allergies;
  final List<String>? chronicDiseases;
  final String? antecedent;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool accountStatus;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  const PatientEntity({
    this.id,
    required this.fullName,
    required this.email,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.phoneNumber,
    this.address,
    this.bloodType,
    this.height,
    this.weight,
    this.allergies,
    this.chronicDiseases,
    this.antecedent,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.accountStatus = true,
    this.lastLogin,
    this.createdAt,
  });

  PatientEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? phoneNumber,
    String? address,
    String? bloodType,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? chronicDiseases,
    String? antecedent,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? accountStatus,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) {
    return PatientEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      antecedent: antecedent ?? this.antecedent,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      accountStatus: accountStatus ?? this.accountStatus,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PatientEntity(id: $id, fullName: $fullName, email: $email, accountStatus: $accountStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatientEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
