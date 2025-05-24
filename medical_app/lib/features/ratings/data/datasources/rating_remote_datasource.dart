import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/ratings/data/models/doctor_rating_model.dart';
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';

abstract class RatingRemoteDataSource {
  /// Submit a rating for a doctor
  Future<void> submitDoctorRating(DoctorRatingModel rating);

  /// Get all ratings for a specific doctor
  Future<List<DoctorRatingModel>> getDoctorRatings(String doctorId);

  /// Get average rating for a doctor
  Future<double> getDoctorAverageRating(String doctorId);

  /// Check if patient has already rated a specific appointment
  Future<bool> hasPatientRatedAppointment(String patientId, String rendezVousId);
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  final FirebaseFirestore firestore;
  final NotificationRemoteDataSource notificationRemoteDataSource;

  RatingRemoteDataSourceImpl({
    required this.firestore,
    required this.notificationRemoteDataSource,
  });

  Future<void> _sendRatingNotification({
    required DoctorRatingModel rating,
    required String ratingId,
  }) async {
    try {
      // Get patient details
      final patientDoc = await firestore.collection('patients').doc(rating.patientId).get();
      final patientName = patientDoc.get('name') ?? 'A patient';
      final patientPhoto = patientDoc.get('photoUrl');

      // Get doctor details
      final doctorDoc = await firestore.collection('medecins').doc(rating.doctorId).get();
      final doctorName = doctorDoc.get('name') ?? 'Doctor';

      // Determine notification content based on rating value
      String ratingComment;
      if (rating.rating >= 4.5) {
        ratingComment = 'Excellent rating from $patientName!';
      } else if (rating.rating >= 3.5) {
        ratingComment = 'Good rating from $patientName';
      } else if (rating.rating >= 2.5) {
        ratingComment = 'Average rating from $patientName';
      } else {
        ratingComment = 'Critical rating from $patientName';
      }

      await notificationRemoteDataSource.sendNotification(
        title: 'New Rating: ${rating.rating} ⭐',
        body: ratingComment,
        senderId: rating.patientId,
        recipientId: rating.doctorId,
        type: NotificationType.newRating,
        ratingId: ratingId,
        appointmentId: rating.rendezVousId,
        data: {
          'patientName': patientName,
          'doctorName': doctorName,
          'rating': rating.rating.toString(),
          'comment': rating.comment ?? '',
          if (patientPhoto != null) 'patientPhoto': patientPhoto,
        },
        recipientRole: 'doctor',
      );

      print('Rating notification sent to Dr. $doctorName');
    } catch (e) {
      print('Error sending rating notification: $e');
      // Don't throw to allow rating submission to complete
    }
  }

  @override
  Future<void> submitDoctorRating(DoctorRatingModel rating) async {
    try {
      // Validate rating
      if (rating.rating < 1 || rating.rating > 5) {
        throw ServerException('Rating must be between 1 and 5 stars');
      }

      // Check if patient already rated this appointment
      final hasRated = await hasPatientRatedAppointment(
        rating.patientId,
        rating.rendezVousId,
      );

      if (hasRated) {
        throw ServerException('You have already rated this appointment');
      }

      // Create rating document
      final docRef = firestore.collection('doctor_ratings').doc();
      final ratingWithId = rating.copyWith(id: docRef.id).toJson();

      // Batch operation to:
      // 1. Create rating
      // 2. Update doctor's average rating
      final batch = firestore.batch();

      batch.set(docRef, ratingWithId);

      // Update doctor's rating stats
      final doctorRef = firestore.collection('medecins').doc(rating.doctorId);
      batch.update(doctorRef, {
        'ratingCount': FieldValue.increment(1),
        'ratingTotal': FieldValue.increment(rating.rating),
      });

      await batch.commit();

      // Send notification
      await _sendRatingNotification(
        rating: rating,
        ratingId: docRef.id,
      );

      // Update appointment to mark as rated
      await firestore.collection('rendez_vous').doc(rating.rendezVousId).update({
        'isRated': true,
      });
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to submit rating: ${e.toString()}');
    }
  }

  @override
  Future<List<DoctorRatingModel>> getDoctorRatings(String doctorId) async {
    try {
      final snapshot = await firestore
          .collection('doctor_ratings')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DoctorRatingModel.fromJson(doc.data()!))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get ratings: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<double> getDoctorAverageRating(String doctorId) async {
    try {
      // Get from cached doctor document for better performance
      final doc = await firestore.collection('medecins').doc(doctorId).get();

      if (!doc.exists) {
        throw ServerException('Doctor not found');
      }

      final data = doc.data()!;
      final count = data['ratingCount'] as int? ?? 0;

      if (count == 0) {
        return 0.0;
      }

      final total = data['ratingTotal'] as double? ?? 0.0;
      return total / count;
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get average rating: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> hasPatientRatedAppointment(String patientId, String rendezVousId) async {
    try {
      final snapshot = await firestore
          .collection('doctor_ratings')
          .where('patientId', isEqualTo: patientId)
          .where('rendezVousId', isEqualTo: rendezVousId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw ServerException('Failed to check rating status: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
}