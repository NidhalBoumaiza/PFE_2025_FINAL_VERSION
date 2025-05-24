import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/features/ratings/domain/entities/doctor_rating_entity.dart';

class DoctorRatingModel extends DoctorRatingEntity {
  DoctorRatingModel({
    String? id,
    required String doctorId,
    required String patientId,
    String? patientName,
    required double rating,
    String? comment,
    required DateTime createdAt,
    required String rendezVousId,
  }) : super(
    id: id,
    doctorId: doctorId,
    patientId: patientId,
    patientName: patientName,
    rating: _validateRating(rating),
    comment: comment,
    createdAt: createdAt,
    rendezVousId: rendezVousId,
  );

  // Rating validation (1-5 stars)
  static double _validateRating(double rating) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5 stars');
    }
    return rating;
  }

  factory DoctorRatingModel.fromEntity(DoctorRatingEntity entity) {
    return DoctorRatingModel(
      id: entity.id,
      doctorId: entity.doctorId,
      patientId: entity.patientId,
      patientName: entity.patientName,
      rating: entity.rating,
      comment: entity.comment,
      createdAt: entity.createdAt,
      rendezVousId: entity.rendezVousId,
    );
  }

  factory DoctorRatingModel.fromJson(Map<String, dynamic> json) {
    try {
      return DoctorRatingModel(
        id: json['id'] as String?,
        doctorId: json['doctorId'] as String,
        patientId: json['patientId'] as String,
        patientName: json['patientName'] as String?,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String?,
        createdAt: _parseDateTime(json['createdAt']),
        rendezVousId: json['rendezVousId'] as String,
      );
    } catch (e) {
      throw FormatException('Failed to parse DoctorRatingModel: $e');
    }
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date is String) {
      return DateTime.parse(date);
    } else if (date is Timestamp) {
      return date.toDate();
    }
    throw FormatException('Invalid date format');
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'rating': rating,
      if (comment != null) 'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'rendezVousId': rendezVousId,
    };
  }

  DoctorRatingModel copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? patientName,
    double? rating,
    String? comment,
    DateTime? createdAt,
    String? rendezVousId,
  }) {
    return DoctorRatingModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      rating: rating != null ? _validateRating(rating) : this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      rendezVousId: rendezVousId ?? this.rendezVousId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DoctorRatingModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              doctorId == other.doctorId &&
              patientId == other.patientId &&
              rating == other.rating &&
              rendezVousId == other.rendezVousId;

  @override
  int get hashCode =>
      id.hashCode ^
      doctorId.hashCode ^
      patientId.hashCode ^
      rating.hashCode ^
      rendezVousId.hashCode;

  @override
  String toString() {
    return 'DoctorRatingModel('
        'id: $id, '
        'doctorId: $doctorId, '
        'patientId: $patientId, '
        'rating: $rating, '
        'rendezVousId: $rendezVousId)';
  }
}