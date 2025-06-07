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

  // CRUD operations
  Future<Unit> createPatient(PatientModel patient, String password);
  Future<Unit> createDoctor(DoctorModel doctor, String password);
  Future<Unit> updatePatient(PatientModel patient);
  Future<Unit> updateDoctor(DoctorModel doctor);
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

          // Add the document ID to the data
          data['id'] = doc.id;

          final patient = PatientModel.fromFirestore(data);
          patients.add(patient);
          print('✅ Successfully processed patient: ${patient.fullName}');
        } catch (e) {
          print('❌ Error processing patient document ${doc.id}: $e');
          print('📄 Document data: ${doc.data()}');
        }
      }

      print('🎉 Successfully processed ${patients.length} patients');
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

          // Add the document ID to the data
          data['id'] = doc.id;

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

      print('🎉 Successfully processed ${doctors.length} doctors');
      return doctors;
    } catch (e) {
      print('💥 Error fetching doctors: $e');
      rethrow;
    }
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
          data['id'] = doc.id;

          final patient = PatientModel.fromFirestore(data);
          patients.add(patient);
        } catch (e) {
          print('❌ Error in patients stream for doc ${doc.id}: $e');
        }
      }

      print('✅ Patients stream processed ${patients.length} patients');
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
          data['id'] = doc.id;

          final doctor = DoctorModel.fromFirestore(data);
          doctors.add(doctor);
        } catch (e) {
          print('❌ Error in doctors stream for doc ${doc.id}: $e');
        }
      }

      print('✅ Doctors stream processed ${doctors.length} doctors');
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
  Future<Unit> createPatient(PatientModel patient, String password) async {
    try {
      print('createPatient: Starting for email=${patient.email}');
      final normalizedEmail = patient.email.toLowerCase().trim();

      // Check for existing email in both collections
      final collections = ['patients', 'medecins'];
      for (var collection in collections) {
        final emailQuery =
            await firestore
                .collection(collection)
                .where('email', isEqualTo: normalizedEmail)
                .get();
        if (emailQuery.docs.isNotEmpty) {
          throw ServerException('Email already exists');
        }

        if (patient.phoneNumber != null && patient.phoneNumber!.isNotEmpty) {
          final phoneQuery =
              await firestore
                  .collection(collection)
                  .where('phoneNumber', isEqualTo: patient.phoneNumber)
                  .get();
          if (phoneQuery.docs.isNotEmpty) {
            throw ServerException('Phone number already exists');
          }
        }
      }

      // Create Firebase Auth user
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Create patient with Firebase UID
        final newPatient = PatientModel(
          id: firebaseUser.uid,
          fullName: patient.fullName,
          email: normalizedEmail,
          gender: patient.gender,
          phoneNumber: patient.phoneNumber ?? '',
          dateOfBirth: patient.dateOfBirth,
          age: patient.age,
          accountStatus: true, // Admin creates active accounts
          antecedent: patient.antecedent,
          bloodType: patient.bloodType,
          height: patient.height,
          weight: patient.weight,
          allergies: patient.allergies,
          chronicDiseases: patient.chronicDiseases,
          emergencyContactName: patient.emergencyContactName,
          emergencyContactPhone: patient.emergencyContactPhone,
          address: patient.address,
          createdAt: DateTime.now(),
          lastLogin: null,
        );

        // Save to patients collection
        await firestore
            .collection('patients')
            .doc(firebaseUser.uid)
            .set(newPatient.toFirestore());

        // Save minimal data to users collection for notifications
        await firestore.collection('users').doc(firebaseUser.uid).set({
          'id': firebaseUser.uid,
          'fullName': patient.fullName,
          'email': normalizedEmail,
          'role': 'patient',
        });

        print('createPatient: Patient created successfully');
        return unit;
      } else {
        throw ServerException('Failed to create Firebase user');
      }
    } catch (e) {
      print('createPatient: Error: $e');
      throw ServerException('Failed to create patient: $e');
    }
  }

  @override
  Future<Unit> createDoctor(DoctorModel doctor, String password) async {
    try {
      print('createDoctor: Starting for email=${doctor.email}');
      final normalizedEmail = doctor.email.toLowerCase().trim();

      // Check for existing email in both collections
      final collections = ['patients', 'medecins'];
      for (var collection in collections) {
        final emailQuery =
            await firestore
                .collection(collection)
                .where('email', isEqualTo: normalizedEmail)
                .get();
        if (emailQuery.docs.isNotEmpty) {
          throw ServerException('Email already exists');
        }

        if (doctor.phoneNumber != null && doctor.phoneNumber!.isNotEmpty) {
          final phoneQuery =
              await firestore
                  .collection(collection)
                  .where('phoneNumber', isEqualTo: doctor.phoneNumber)
                  .get();
          if (phoneQuery.docs.isNotEmpty) {
            throw ServerException('Phone number already exists');
          }
        }
      }

      // Create Firebase Auth user
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Create doctor with Firebase UID
        final newDoctor = DoctorModel(
          id: firebaseUser.uid,
          fullName: doctor.fullName,
          email: normalizedEmail,
          gender: doctor.gender,
          phoneNumber: doctor.phoneNumber ?? '',
          dateOfBirth: doctor.dateOfBirth,
          age: doctor.age,
          accountStatus: true, // Admin creates active accounts
          speciality: doctor.speciality,
          numLicence: doctor.numLicence,
          appointmentDuration: doctor.appointmentDuration,
          experienceYears: doctor.experienceYears,
          educationSummary: doctor.educationSummary,
          consultationFee: doctor.consultationFee,
          address: doctor.address,
          createdAt: DateTime.now(),
          lastLogin: null,
        );

        // Save to medecins collection
        await firestore
            .collection('medecins')
            .doc(firebaseUser.uid)
            .set(newDoctor.toFirestore());

        // Save minimal data to users collection for notifications
        await firestore.collection('users').doc(firebaseUser.uid).set({
          'id': firebaseUser.uid,
          'fullName': doctor.fullName,
          'email': normalizedEmail,
          'role': 'medecin',
        });

        print('createDoctor: Doctor created successfully');
        return unit;
      } else {
        throw ServerException('Failed to create Firebase user');
      }
    } catch (e) {
      print('createDoctor: Error: $e');
      throw ServerException('Failed to create doctor: $e');
    }
  }

  @override
  Future<Unit> updatePatient(PatientModel patient) async {
    try {
      print('updatePatient: Starting for patient id=${patient.id}');

      if (patient.id == null) {
        throw ServerException('Patient ID is required for update');
      }

      final normalizedEmail = patient.email.toLowerCase().trim();

      // Update patient in patients collection
      await firestore
          .collection('patients')
          .doc(patient.id)
          .update(patient.toFirestore());

      // Update minimal data in users collection
      await firestore.collection('users').doc(patient.id).update({
        'fullName': patient.fullName,
        'email': normalizedEmail,
      });

      print('updatePatient: Patient updated successfully');
      return unit;
    } catch (e) {
      print('updatePatient: Error: $e');
      throw ServerException('Failed to update patient: $e');
    }
  }

  @override
  Future<Unit> updateDoctor(DoctorModel doctor) async {
    try {
      print('updateDoctor: Starting for doctor id=${doctor.id}');

      if (doctor.id == null) {
        throw ServerException('Doctor ID is required for update');
      }

      final normalizedEmail = doctor.email.toLowerCase().trim();

      // Update doctor in medecins collection
      await firestore
          .collection('medecins')
          .doc(doctor.id)
          .update(doctor.toFirestore());

      // Update minimal data in users collection
      await firestore.collection('users').doc(doctor.id).update({
        'fullName': doctor.fullName,
        'email': normalizedEmail,
      });

      print('updateDoctor: Doctor updated successfully');
      return unit;
    } catch (e) {
      print('updateDoctor: Error: $e');
      throw ServerException('Failed to update doctor: $e');
    }
  }

  @override
  Future<Unit> deleteUser(String userId, String userType) async {
    try {
      print('deleteUser: Starting for userId=$userId, userType=$userType');

      // Create batch for atomic operations
      final batch = firestore.batch();

      // Delete from main collection (patients or medecins)
      if (userType == 'patient') {
        batch.delete(firestore.collection('patients').doc(userId));
      } else if (userType == 'medecin' || userType == 'doctor') {
        batch.delete(firestore.collection('medecins').doc(userId));
      }

      // Delete from users collection
      batch.delete(firestore.collection('users').doc(userId));

      // Delete related data
      // Delete notifications
      final notificationsQuery =
          await firestore
              .collection('notifications')
              .where('recipientId', isEqualTo: userId)
              .get();
      for (final doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
      }

      final sentNotificationsQuery =
          await firestore
              .collection('notifications')
              .where('senderId', isEqualTo: userId)
              .get();
      for (final doc in sentNotificationsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete appointments
      final appointmentsQuery =
          await firestore
              .collection('rendez_vous')
              .where('patientId', isEqualTo: userId)
              .get();
      for (final doc in appointmentsQuery.docs) {
        batch.delete(doc.reference);
      }

      final doctorAppointmentsQuery =
          await firestore
              .collection('rendez_vous')
              .where('doctorId', isEqualTo: userId)
              .get();
      for (final doc in doctorAppointmentsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete conversations
      final conversationsQuery =
          await firestore
              .collection('conversations')
              .where('participants', arrayContains: userId)
              .get();
      for (final doc in conversationsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete prescriptions
      final prescriptionsQuery =
          await firestore
              .collection('prescriptions')
              .where('patientId', isEqualTo: userId)
              .get();
      for (final doc in prescriptionsQuery.docs) {
        batch.delete(doc.reference);
      }

      final doctorPrescriptionsQuery =
          await firestore
              .collection('prescriptions')
              .where('doctorId', isEqualTo: userId)
              .get();
      for (final doc in doctorPrescriptionsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete ratings
      final ratingsQuery =
          await firestore
              .collection('ratings')
              .where('patientId', isEqualTo: userId)
              .get();
      for (final doc in ratingsQuery.docs) {
        batch.delete(doc.reference);
      }

      final doctorRatingsQuery =
          await firestore
              .collection('ratings')
              .where('doctorId', isEqualTo: userId)
              .get();
      for (final doc in doctorRatingsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete medical files if patient
      if (userType == 'patient') {
        final medicalFilesQuery =
            await firestore
                .collection('dossier_medical')
                .where('patientId', isEqualTo: userId)
                .get();
        for (final doc in medicalFilesQuery.docs) {
          batch.delete(doc.reference);
        }
      }

      // Commit all deletions
      await batch.commit();

      // Note: We don't delete the Firebase Auth user here as that requires
      // the user to be currently authenticated. In a real admin system,
      // you might want to use Firebase Admin SDK for this.

      print('deleteUser: User data deleted successfully');
      return unit;
    } catch (e) {
      print('deleteUser: Error: $e');
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

      int activePatients = 0;
      int inactivePatients = 0;
      int activeDoctors = 0;
      int inactiveDoctors = 0;

      // Count active/inactive patients based on appointments
      for (var patient in patients) {
        final appointmentCount = await getUserAppointmentCount(
          patient.id!,
          'patient',
        );
        if (appointmentCount >= 5) {
          activePatients++;
        } else {
          inactivePatients++;
        }
      }

      // Count active/inactive doctors based on appointments
      for (var doctor in doctors) {
        final appointmentCount = await getUserAppointmentCount(
          doctor.id!,
          'doctor',
        );
        if (appointmentCount >= 5) {
          activeDoctors++;
        } else {
          inactiveDoctors++;
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

      print('📈 Statistics calculated: $stats');
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
