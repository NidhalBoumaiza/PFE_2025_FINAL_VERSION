import '../../domain/entities/prescription_entity.dart';

class MedicationModel {
  final String id;
  final String name;
  final String dosage;
  final String instructions;

  MedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.instructions,
  });

  factory MedicationModel.fromEntity(MedicationEntity entity) {
    return MedicationModel(
      id: entity.id,
      name: entity.name,
      dosage: entity.dosage,
      instructions: entity.instructions,
    );
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      instructions: json['instructions'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'instructions': instructions,
    };
  }

  MedicationEntity toEntity() {
    return MedicationEntity(
      id: id,
      name: name,
      dosage: dosage,
      instructions: instructions,
    );
  }
} 