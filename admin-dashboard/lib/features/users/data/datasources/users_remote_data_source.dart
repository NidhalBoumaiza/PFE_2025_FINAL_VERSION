import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../models/patient_model.dart';
import '../models/doctor_model.dart';

abstract class UsersRemoteDataSource {
  Future<List<PatientModel>> getPatients();
  Future<List<DoctorModel>> getDoctors();
  Stream<List<PatientModel>> getPatientsStream();
  Stream<List<DoctorModel>> getDoctorsStream();
  Future<void> refreshData();

  // Only delete operation remains
  Future<Unit> deleteUser(String userId, String userType);

  // Statistics methods
  Future<Map<String, int>> getUserStatistics();
  Future<int> getUserAppointmentCount(String userId, String userType);
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  UsersRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  int generateFourDigitNumber() {
    final random = Random();
    return 1000 + random.nextInt(9000);
  }

  @override
  Future<List<PatientModel>> getPatients() async {
    try {
      print('🔍 Fetching patients from "patients" collection...');

      final querySnapshot = await firestore.collection('patients').get();

      print('📊 Found ${querySnapshot.docs.length} patient documents');

      final patients = <PatientModel>[];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('📄 Processing patient doc ${doc.id}: ${data.keys.toList()}');

          // Validate required fields for a valid patient
          if (!_isValidPatient(data)) {
            print('❌ Skipping invalid patient ${doc.id}: missing required fields');
            continue;
          }

          // Add the document ID to the data
          data['id'] = doc.id;
          
          // Construct fullName from name and lastName
          final name = data['name']?.toString().trim() ?? '';
          final lastName = data['lastName']?.toString().trim() ?? '';
          data['fullName'] = '$name $lastName'.trim();

          final patient = PatientModel.fromFirestore(data);
          patients.add(patient);
          print('✅ Successfully processed patient: ${patient.fullName}');
        } catch (e) {
          print('❌ Error processing patient document ${doc.id}: $e');
          print('📄 Document data: ${doc.data()}');
        }
      }

      print('🎉 Successfully processed ${patients.length} valid patients out of ${querySnapshot.docs.length} documents');
      return patients;
    } catch (e) {
      print('💥 Error fetching patients: $e');
      rethrow;
    }
  }

  @override
  Future<List<DoctorModel>> getDoctors() async {
    try {
      print('🔍 Fetching doctors from "medecins" collection...');

      final querySnapshot = await firestore.collection('medecins').get();

      print('📊 Found ${querySnapshot.docs.length} doctor documents');

      final doctors = <DoctorModel>[];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('📄 Processing doctor doc ${doc.id}: ${data.keys.toList()}');

          // Validate required fields for a valid doctor
          if (!_isValidDoctor(data)) {
            print('❌ Skipping invalid doctor ${doc.id}: missing required fields');
            continue;
          }

          // Add the document ID to the data
          data['id'] = doc.id;
          
          // Construct fullName from name and lastName
          final name = data['name']?.toString().trim() ?? '';
          final lastName = data['lastName']?.toString().trim() ?? '';
          data['fullName'] = '$name $lastName'.trim();

          final doctor = DoctorModel.fromFirestore(data);
          doctors.add(doctor);
          print(
            '✅ Successfully processed doctor: ${doctor.fullName} (${doctor.speciality})',
          );
        } catch (e) {
          print('❌ Error processing doctor document ${doc.id}: $e');
          print('📄 Document data: ${doc.data()}');
        }
      }

      print('🎉 Successfully processed ${doctors.length} valid doctors out of ${querySnapshot.docs.length} documents');
      return doctors;
    } catch (e) {
      print('💥 Error fetching doctors: $e');
      rethrow;
    }
  }

  /// Validates if a patient document has all required fields
  bool _isValidPatient(Map<String, dynamic> data) {
    // Check for required fields
    final hasName = data['name'] != null && data['name'].toString().trim().isNotEmpty;
    final hasLastName = data['lastName'] != null && data['lastName'].toString().trim().isNotEmpty;
    final hasEmail = data['email'] != null && data['email'].toString().trim().isNotEmpty;
    
    // Role validation - should be 'patient' or not specified (defaults to patient)
    final role = data['role']?.toString().toLowerCase();
    final hasValidRole = role == null || role == 'patient';

    final isValid = hasName && hasLastName && hasEmail && hasValidRole;
    
    if (!isValid) {
      print('🔍 Patient validation failed:');
      print('  - Name: ${hasName ? "✅" : "❌"} (${data['name']})');
      print('  - LastName: ${hasLastName ? "✅" : "❌"} (${data['lastName']})');
      print('  - Email: ${hasEmail ? "✅" : "❌"} (${data['email']})');
      print('  - Role: ${hasValidRole ? "✅" : "❌"} (${data['role']})');
    }
    
    return isValid;
  }

  /// Validates if a doctor document has all required fields
  bool _isValidDoctor(Map<String, dynamic> data) {
    // Check for required fields
    final hasName = data['name'] != null && data['name'].toString().trim().isNotEmpty;
    final hasLastName = data['lastName'] != null && data['lastName'].toString().trim().isNotEmpty;
    final hasEmail = data['email'] != null && data['email'].toString().trim().isNotEmpty;
    
    // Role validation - should be 'medecin' or 'doctor'
    final role = data['role']?.toString().toLowerCase();
    final hasValidRole = role == 'medecin' || role == 'doctor';

    // Optional but recommended fields
    final hasSpeciality = data['speciality'] != null && data['speciality'].toString().trim().isNotEmpty;
    
    final isValid = hasName && hasLastName && hasEmail && hasValidRole;
    
    if (!isValid) {
      print('🔍 Doctor validation failed:');
      print('  - Name: ${hasName ? "✅" : "❌"} (${data['name']})');
      print('  - LastName: ${hasLastName ? "✅" : "❌"} (${data['lastName']})');
      print('  - Email: ${hasEmail ? "✅" : "❌"} (${data['email']})');
      print('  - Role: ${hasValidRole ? "✅" : "❌"} (${data['role']})');
      print('  - Speciality: ${hasSpeciality ? "✅" : "⚠️"} (${data['speciality']}) - Optional');
    }
    
    return isValid;
  }

  @override
  Stream<List<PatientModel>> getPatientsStream() {
    print('🔄 Starting patients stream from "patients" collection...');

    return firestore.collection('patients').snapshots().map((snapshot) {
      print('📡 Patients stream update: ${snapshot.docs.length} documents');

      final patients = <PatientModel>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Validate required fields for a valid patient
          if (!_isValidPatient(data)) {
            print('❌ Skipping invalid patient ${doc.id} in stream: missing required fields');
            continue;
          }
          
          data['id'] = doc.id;
          
          // Construct fullName from name and lastName
          final name = data['name']?.toString().trim() ?? '';
          final lastName = data['lastName']?.toString().trim() ?? '';
          data['fullName'] = '$name $lastName'.trim();

          final patient = PatientModel.fromFirestore(data);
          patients.add(patient);
        } catch (e) {
          print('❌ Error in patients stream for doc ${doc.id}: $e');
        }
      }

      print('✅ Patients stream processed ${patients.length} valid patients out of ${snapshot.docs.length} documents');
      return patients;
    });
  }

  @override
  Stream<List<DoctorModel>> getDoctorsStream() {
    print('🔄 Starting doctors stream from "medecins" collection...');

    return firestore.collection('medecins').snapshots().map((snapshot) {
      print('📡 Doctors stream update: ${snapshot.docs.length} documents');

      final doctors = <DoctorModel>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Validate required fields for a valid doctor
          if (!_isValidDoctor(data)) {
            print('❌ Skipping invalid doctor ${doc.id} in stream: missing required fields');
            continue;
          }
          
          data['id'] = doc.id;
          
          // Construct fullName from name and lastName
          final name = data['name']?.toString().trim() ?? '';
          final lastName = data['lastName']?.toString().trim() ?? '';
          data['fullName'] = '$name $lastName'.trim();

          final doctor = DoctorModel.fromFirestore(data);
          doctors.add(doctor);
        } catch (e) {
          print('❌ Error in doctors stream for doc ${doc.id}: $e');
        }
      }

      print('✅ Doctors stream processed ${doctors.length} valid doctors out of ${snapshot.docs.length} documents');
      return doctors;
    });
  }

  @override
  Future<void> refreshData() async {
    print('🔄 Refreshing all user data...');
    // This method can be used to trigger cache refresh if needed
    // For now, it's just a placeholder since we're using real-time streams
  }

  @override
  Future<Unit> deleteUser(String userId, String userType) async {
    try {
      print('🗑️ deleteUser: Starting for userId=$userId, userType=$userType');

      // Validate inputs
      if (userId.isEmpty) {
        throw ServerException('User ID cannot be empty');
      }

      // Create batch for atomic operations
      WriteBatch batch = firestore.batch();
      int operationCount = 0;

      // Helper function to add delete operation to batch
      void addDeleteToBatch(DocumentReference docRef) {
        if (operationCount >= 450) {
          // Stay under 500 limit with safety margin
          // Commit current batch and create new one
          batch.commit();
          batch = firestore.batch();
          operationCount = 0;
        }
        batch.delete(docRef);
        operationCount++;
      }

      print('📋 deleteUser: Step 1 - Deleting from main collection');
      // Delete from main collection (patients or medecins)
      if (userType == 'patient') {
        print('👤 deleteUser: Deleting from patients collection');
        addDeleteToBatch(firestore.collection('patients').doc(userId));
      } else if (userType == 'medecin' || userType == 'doctor') {
        print('👨‍⚕️ deleteUser: Deleting from medecins collection');
        addDeleteToBatch(firestore.collection('medecins').doc(userId));
      } else {
        print('❌ deleteUser: Invalid userType: $userType');
        throw ServerException('Invalid user type: $userType');
      }

      print('👥 deleteUser: Step 2 - Deleting from users collection');
      // Delete from users collection
      addDeleteToBatch(firestore.collection('users').doc(userId));

      print('🔔 deleteUser: Step 3 - Deleting notifications');
      // Delete related data - notifications
      try {
      final notificationsQuery =
          await firestore
              .collection('notifications')
              .where('recipientId', isEqualTo: userId)
              .get();
        print(
          '📧 deleteUser: Found ${notificationsQuery.docs.length} recipient notifications',
        );
      for (final doc in notificationsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }

      final sentNotificationsQuery =
          await firestore
              .collection('notifications')
              .where('senderId', isEqualTo: userId)
              .get();
        print(
          '📤 deleteUser: Found ${sentNotificationsQuery.docs.length} sender notifications',
        );
      for (final doc in sentNotificationsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }
      } catch (e) {
        print('⚠️ deleteUser: Error deleting notifications: $e');
        // Continue with other deletions
      }

      print('📅 deleteUser: Step 4 - Deleting appointments');
      // Delete appointments
      try {
      final appointmentsQuery =
          await firestore
              .collection('rendez_vous')
              .where('patientId', isEqualTo: userId)
              .get();
        print(
          '👤📅 deleteUser: Found ${appointmentsQuery.docs.length} patient appointments',
        );
      for (final doc in appointmentsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }

      final doctorAppointmentsQuery =
          await firestore
              .collection('rendez_vous')
              .where('doctorId', isEqualTo: userId)
              .get();
        print(
          '👨‍⚕️📅 deleteUser: Found ${doctorAppointmentsQuery.docs.length} doctor appointments',
        );
      for (final doc in doctorAppointmentsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }
      } catch (e) {
        print('⚠️ deleteUser: Error deleting appointments: $e');
        // Continue with other deletions
      }

      print('💬 deleteUser: Step 5 - Deleting conversations');
      // Delete conversations
      try {
      final conversationsQuery =
          await firestore
              .collection('conversations')
              .where('participants', arrayContains: userId)
              .get();
        print(
          '💬 deleteUser: Found ${conversationsQuery.docs.length} conversations',
        );
      for (final doc in conversationsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }
      } catch (e) {
        print('⚠️ deleteUser: Error deleting conversations: $e');
        // Continue with other deletions
      }

      print('💊 deleteUser: Step 6 - Deleting prescriptions');
      // Delete prescriptions
      try {
      final prescriptionsQuery =
          await firestore
              .collection('prescriptions')
              .where('patientId', isEqualTo: userId)
              .get();
        print(
          '👤💊 deleteUser: Found ${prescriptionsQuery.docs.length} patient prescriptions',
        );
      for (final doc in prescriptionsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }

      final doctorPrescriptionsQuery =
          await firestore
              .collection('prescriptions')
              .where('doctorId', isEqualTo: userId)
              .get();
        print(
          '👨‍⚕️💊 deleteUser: Found ${doctorPrescriptionsQuery.docs.length} doctor prescriptions',
        );
      for (final doc in doctorPrescriptionsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }
      } catch (e) {
        print('⚠️ deleteUser: Error deleting prescriptions: $e');
        // Continue with other deletions
      }

      print('⭐ deleteUser: Step 7 - Deleting ratings');
      // Delete ratings
      try {
      final ratingsQuery =
          await firestore
              .collection('ratings')
              .where('patientId', isEqualTo: userId)
              .get();
        print(
          '👤⭐ deleteUser: Found ${ratingsQuery.docs.length} patient ratings',
        );
      for (final doc in ratingsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }

      final doctorRatingsQuery =
          await firestore
              .collection('ratings')
              .where('doctorId', isEqualTo: userId)
              .get();
        print(
          '👨‍⚕️⭐ deleteUser: Found ${doctorRatingsQuery.docs.length} doctor ratings',
        );
      for (final doc in doctorRatingsQuery.docs) {
          addDeleteToBatch(doc.reference);
      }
      } catch (e) {
        print('⚠️ deleteUser: Error deleting ratings: $e');
        // Continue with other deletions
      }

      print('📋 deleteUser: Step 8 - Deleting medical files (if patient)');
      // Delete medical files if patient
      if (userType == 'patient') {
        try {
        final medicalFilesQuery =
            await firestore
                .collection('dossier_medical')
                .where('patientId', isEqualTo: userId)
                .get();
          print(
            '📋 deleteUser: Found ${medicalFilesQuery.docs.length} medical files',
          );
        for (final doc in medicalFilesQuery.docs) {
            addDeleteToBatch(doc.reference);
        }
        } catch (e) {
          print('⚠️ deleteUser: Error deleting medical files: $e');
          // Continue with other deletions
        }
      }

      print(
        '💾 deleteUser: Step 9 - Committing final batch with $operationCount operations',
      );
      // Commit final batch
      if (operationCount > 0) {
      await batch.commit();
      }

      print('✅ deleteUser: User data deleted successfully');
      print(
        '🔄 deleteUser: Note - Firebase Auth user deletion requires Admin SDK',
      );

      return unit;
    } on FirebaseException catch (e) {
      print('🔥 deleteUser: Firebase error: ${e.code} - ${e.message}');
      throw ServerException('Firebase error: ${e.message}');
    } catch (e) {
      print('💥 deleteUser: Unexpected error: $e');
      print('📍 deleteUser: Error type: ${e.runtimeType}');
      throw ServerException('Failed to delete user: $e');
    }
  }

  @override
  Future<Map<String, int>> getUserStatistics() async {
    try {
      print('📊 Calculating user statistics based on appointment activity...');

      // Get all patients and doctors
      final patients = await getPatients();
      final doctors = await getDoctors();

      print('📈 Found ${patients.length} patients and ${doctors.length} doctors');

      int activePatients = 0;
      int inactivePatients = 0;
      int activeDoctors = 0;
      int inactiveDoctors = 0;

      // Count active/inactive patients based on appointments (threshold: 5 appointments)
      print('🔍 Analyzing patient activity...');
      for (var patient in patients) {
        final appointmentCount = await getUserAppointmentCount(
          patient.id!,
          'patient',
        );
        if (appointmentCount >= 5) {
          activePatients++;
          print('✅ Active patient: ${patient.fullName} ($appointmentCount appointments)');
        } else {
          inactivePatients++;
          print('💤 Inactive patient: ${patient.fullName} ($appointmentCount appointments)');
        }
      }

      // Count active/inactive doctors based on appointments (threshold: 5 appointments)
      print('🔍 Analyzing doctor activity...');
      for (var doctor in doctors) {
        final appointmentCount = await getUserAppointmentCount(
          doctor.id!,
          'doctor',
        );
        if (appointmentCount >= 5) {
          activeDoctors++;
          print('✅ Active doctor: ${doctor.fullName} ($appointmentCount appointments)');
        } else {
          inactiveDoctors++;
          print('💤 Inactive doctor: ${doctor.fullName} ($appointmentCount appointments)');
        }
      }

      final stats = {
        'activePatients': activePatients,
        'inactivePatients': inactivePatients,
        'activeDoctors': activeDoctors,
        'inactiveDoctors': inactiveDoctors,
        'totalPatients': patients.length,
        'totalDoctors': doctors.length,
        'totalUsers': patients.length + doctors.length,
        'totalActiveUsers': activePatients + activeDoctors,
        'totalInactiveUsers': inactivePatients + inactiveDoctors,
      };

      print('📈 Final Statistics:');
      print('   👥 Total Users: ${stats['totalUsers']}');
      print('   👤 Total Patients: ${stats['totalPatients']} (Active: $activePatients, Inactive: $inactivePatients)');
      print('   👨‍⚕️ Total Doctors: ${stats['totalDoctors']} (Active: $activeDoctors, Inactive: $inactiveDoctors)');
      print('   ✅ Total Active: ${stats['totalActiveUsers']}');
      print('   💤 Total Inactive: ${stats['totalInactiveUsers']}');
      
      return stats;
    } catch (e) {
      print('💥 Error calculating user statistics: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUserAppointmentCount(String userId, String userType) async {
    try {
      print('🔢 Counting appointments for user $userId (type: $userType)');

      QuerySnapshot querySnapshot;

      if (userType == 'patient') {
        // Count appointments where this user is the patient
        querySnapshot =
            await firestore
                .collection('rendez_vous')
                .where('patientId', isEqualTo: userId)
                .get();
      } else {
        // Count appointments where this user is the doctor
        querySnapshot =
            await firestore
                .collection('rendez_vous')
                .where('doctorId', isEqualTo: userId)
                .get();
      }

      final count = querySnapshot.docs.length;
      print('📊 User $userId has $count appointments');
      return count;
    } catch (e) {
      print('💥 Error counting appointments for user $userId: $e');
      return 0; // Return 0 if error occurs
    }
  }
}
