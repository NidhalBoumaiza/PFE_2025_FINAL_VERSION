import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/ratings/data/models/doctor_rating_model.dart';

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

  RatingRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> submitDoctorRating(DoctorRatingModel rating) async {
    try {
      // Check if collection exists
      final CollectionReference ratingsCollection = firestore.collection('doctor_ratings');
      
      // Create a reference for a new document with auto-generated ID
      final docRef = ratingsCollection.doc();
      
      // Add the ID to the rating model
      final ratingWithId = rating.toJson()
        ..['id'] = docRef.id;
      
      // Set the data for the new document
      await docRef.set(ratingWithId);
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<DoctorRatingModel>> getDoctorRatings(String doctorId) async {
    try {
      final QuerySnapshot ratingSnapshot = await firestore
          .collection('doctor_ratings')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true)
          .get();

      return ratingSnapshot.docs
          .map((doc) => DoctorRatingModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<double> getDoctorAverageRating(String doctorId) async {
    try {
      final QuerySnapshot ratingSnapshot = await firestore
          .collection('doctor_ratings')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      if (ratingSnapshot.docs.isEmpty) {
        return 0.0;
      }

      double totalRating = 0;
      for (var doc in ratingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] as num).toDouble();
      }

      return totalRating / ratingSnapshot.docs.length;
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> hasPatientRatedAppointment(String patientId, String rendezVousId) async {
    try {
      final QuerySnapshot ratingSnapshot = await firestore
          .collection('doctor_ratings')
          .where('patientId', isEqualTo: patientId)
          .where('rendezVousId', isEqualTo: rendezVousId)
          .get();

      return ratingSnapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
} 