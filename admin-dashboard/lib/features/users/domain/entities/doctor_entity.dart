class DoctorEntity {
  final String? id;
  final String fullName;
  final String email;
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender;
  final String? phoneNumber;
  final String? address;
  final String? speciality;
  final String? numLicence;
  final String experienceYears;
  final String educationSummary;
  final int appointmentDuration;
  final double? consultationFee;
  final bool accountStatus;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  const DoctorEntity({
    this.id,
    required this.fullName,
    required this.email,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.phoneNumber,
    this.address,
    this.speciality,
    this.numLicence,
    required this.experienceYears,
    required this.educationSummary,
    required this.appointmentDuration,
    this.consultationFee,
    this.accountStatus = true,
    this.lastLogin,
    this.createdAt,
  });

  /// Calculates age from date of birth
  int? get calculatedAge {
    if (dateOfBirth == null) return age; // Fallback to stored age if no dateOfBirth
    
    final now = DateTime.now();
    final birthDate = dateOfBirth!;
    
    int calculatedAge = now.year - birthDate.year;
    
    // Check if birthday hasn't occurred this year yet
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      calculatedAge--;
    }
    
    return calculatedAge >= 0 ? calculatedAge : null;
  }

  DoctorEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? phoneNumber,
    String? address,
    String? speciality,
    String? numLicence,
    String? experienceYears,
    String? educationSummary,
    int? appointmentDuration,
    double? consultationFee,
    bool? accountStatus,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) {
    return DoctorEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      speciality: speciality ?? this.speciality,
      numLicence: numLicence ?? this.numLicence,
      experienceYears: experienceYears ?? this.experienceYears,
      educationSummary: educationSummary ?? this.educationSummary,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      consultationFee: consultationFee ?? this.consultationFee,
      accountStatus: accountStatus ?? this.accountStatus,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'DoctorEntity(id: $id, fullName: $fullName, email: $email, speciality: $speciality, accountStatus: $accountStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
