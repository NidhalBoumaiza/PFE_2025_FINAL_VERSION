import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/stats_entity.dart';
import '../models/stats_model.dart';

abstract class StatsRemoteDataSource {
  Future<StatsModel> getStats();
  Future<Map<String, int>> getAppointmentsPerDay();
  Future<Map<String, int>> getAppointmentsPerMonth();
  Future<Map<String, int>> getAppointmentsPerYear();
  Future<List<DoctorStatistics>> getTopDoctorsByCompletedAppointments();
  Future<List<DoctorStatistics>> getTopDoctorsByCancelledAppointments();
  Future<List<PatientStatistics>> getTopPatientsByCancelledAppointments();
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  final FirebaseFirestore firestore;

  StatsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<StatsModel> getStats() async {
    try {
      // Get patient counts from patients collection
      final patientsQuery = await firestore.collection('patients').get();
      final totalPatients = patientsQuery.docs.length;

      // Get doctor counts from medecins collection
      final doctorsQuery = await firestore.collection('medecins').get();
      final totalDoctors = doctorsQuery.docs.length;

      // Total users (patients + doctors)
      final totalUsers = totalPatients + totalDoctors;

      // Get appointment counts from rendez_vous collection
      final appointmentQuery = await firestore.collection('rendez_vous').get();
      final appointments = appointmentQuery.docs;

      final totalAppointments = appointments.length;
      final pendingAppointments =
          appointments
              .where((appointment) => appointment.data()['status'] == 'pending')
              .length;
      final acceptedAppointments =
          appointments
              .where(
                (appointment) => appointment.data()['status'] == 'accepted',
              )
              .length;
      final rejectedAppointments =
          appointments
              .where(
                (appointment) => appointment.data()['status'] == 'rejected',
              )
              .length;
      final completedAppointments =
          appointments
              .where(
                (appointment) => appointment.data()['status'] == 'completed',
              )
              .length;

      // Get time-based stats
      final appointmentsPerDay = await _getAppointmentsPerDayFromFirestore();
      final appointmentsPerMonth =
          await _getAppointmentsPerMonthFromFirestore();
      final appointmentsPerYear = await _getAppointmentsPerYearFromFirestore();

      // Get top doctors and patients stats
      final topDoctorsByCompletedAppointments =
          await getTopDoctorsByCompletedAppointments();
      final topDoctorsByCancelledAppointments =
          await getTopDoctorsByCancelledAppointments();
      final topPatientsByCancelledAppointments =
          await getTopPatientsByCancelledAppointments();

      return StatsModel(
        totalUsers: totalUsers,
        totalDoctors: totalDoctors,
        totalPatients: totalPatients,
        totalAppointments: totalAppointments,
        pendingAppointments: pendingAppointments,
        completedAppointments: acceptedAppointments + completedAppointments,
        cancelledAppointments: rejectedAppointments,
        appointmentsPerDay: appointmentsPerDay,
        appointmentsPerMonth: appointmentsPerMonth,
        appointmentsPerYear: appointmentsPerYear,
        topDoctorsByCompletedAppointments: topDoctorsByCompletedAppointments,
        topDoctorsByCancelledAppointments: topDoctorsByCancelledAppointments,
        topPatientsByCancelledAppointments: topPatientsByCancelledAppointments,
      );
    } catch (e) {
      print('Error getting stats: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, int>> getAppointmentsPerDay() async {
    try {
      return await _getAppointmentsPerDayFromFirestore();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, int>> getAppointmentsPerMonth() async {
    try {
      return await _getAppointmentsPerMonthFromFirestore();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, int>> getAppointmentsPerYear() async {
    try {
      return await _getAppointmentsPerYearFromFirestore();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<DoctorStatistics>> getTopDoctorsByCompletedAppointments() async {
    try {
      // Get all doctors from medecins collection
      final doctorsQuery = await firestore.collection('medecins').get();

      if (doctorsQuery.docs.isEmpty) {
        return [];
      }

      // For each doctor, count their appointments
      List<DoctorStatistics> doctorStats = [];

      for (var doctorDoc in doctorsQuery.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;

        // Count completed/accepted appointments for this doctor
        final completedAppointmentsQuery =
            await firestore
                .collection('rendez_vous')
                .where('doctorId', isEqualTo: doctorId)
                .where('status', whereIn: ['accepted', 'completed'])
                .get();

        final totalAppointments =
            await firestore
                .collection('rendez_vous')
                .where('doctorId', isEqualTo: doctorId)
                .get();

        final completedCount = completedAppointmentsQuery.docs.length;
        final totalCount = totalAppointments.docs.length;
        final completionRate =
            totalCount > 0 ? completedCount / totalCount : 0.0;

        if (totalCount > 0) {
          doctorStats.add(
            DoctorStatistics(
              id: doctorId,
              name:
                  '${doctorData['name'] ?? 'Unknown'} ${doctorData['lastName'] ?? ''}',
              email: doctorData['email'] ?? '',
              appointmentCount: completedCount,
              completionRate: completionRate,
            ),
          );
        }
      }

      // Sort by appointment count in descending order
      doctorStats.sort(
        (a, b) => b.appointmentCount.compareTo(a.appointmentCount),
      );

      // Return top 10 or less if there are fewer doctors
      return doctorStats.take(10).toList();
    } catch (e) {
      print('Error getting top doctors by completed appointments: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<DoctorStatistics>> getTopDoctorsByCancelledAppointments() async {
    try {
      // Get all doctors from medecins collection
      final doctorsQuery = await firestore.collection('medecins').get();

      if (doctorsQuery.docs.isEmpty) {
        return [];
      }

      // For each doctor, count their cancelled appointments
      List<DoctorStatistics> doctorStats = [];

      for (var doctorDoc in doctorsQuery.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;

        // Count rejected appointments for this doctor
        final rejectedAppointmentsQuery =
            await firestore
                .collection('rendez_vous')
                .where('doctorId', isEqualTo: doctorId)
                .where('status', isEqualTo: 'rejected')
                .get();

        final totalAppointments =
            await firestore
                .collection('rendez_vous')
                .where('doctorId', isEqualTo: doctorId)
                .get();

        final rejectedCount = rejectedAppointmentsQuery.docs.length;
        final totalCount = totalAppointments.docs.length;

        if (totalCount > 0) {
          doctorStats.add(
            DoctorStatistics(
              id: doctorId,
              name:
                  '${doctorData['name'] ?? 'Unknown'} ${doctorData['lastName'] ?? ''}',
              email: doctorData['email'] ?? '',
              appointmentCount: rejectedCount,
              completionRate: totalCount > 0 ? rejectedCount / totalCount : 0.0,
            ),
          );
        }
      }

      // Sort by rejected appointment count in descending order
      doctorStats.sort(
        (a, b) => b.appointmentCount.compareTo(a.appointmentCount),
      );

      // Return top 10 or less if there are fewer doctors
      return doctorStats.take(10).toList();
    } catch (e) {
      print('Error getting top doctors by cancelled appointments: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PatientStatistics>>
  getTopPatientsByCancelledAppointments() async {
    try {
      // Get all patients from patients collection
      final patientsQuery = await firestore.collection('patients').get();

      if (patientsQuery.docs.isEmpty) {
        return [];
      }

      // For each patient, count their cancelled appointments
      List<PatientStatistics> patientStats = [];

      for (var patientDoc in patientsQuery.docs) {
        final patientData = patientDoc.data();
        final patientId = patientDoc.id;

        // Count rejected appointments for this patient
        final rejectedAppointmentsQuery =
            await firestore
                .collection('rendez_vous')
                .where('patientId', isEqualTo: patientId)
                .where('status', isEqualTo: 'rejected')
                .get();

        final totalAppointmentsQuery =
            await firestore
                .collection('rendez_vous')
                .where('patientId', isEqualTo: patientId)
                .get();

        final rejectedCount = rejectedAppointmentsQuery.docs.length;
        final totalCount = totalAppointmentsQuery.docs.length;

        if (rejectedCount > 0) {
          patientStats.add(
            PatientStatistics(
              id: patientId,
              name:
                  '${patientData['name'] ?? 'Unknown'} ${patientData['lastName'] ?? ''}',
              email: patientData['email'] ?? '',
              cancelledAppointments: rejectedCount,
              totalAppointments: totalCount,
              cancellationRate:
                  totalCount > 0 ? rejectedCount / totalCount : 0.0,
            ),
          );
        }
      }

      // Sort by cancellation count in descending order
      patientStats.sort(
        (a, b) => b.cancelledAppointments.compareTo(a.cancelledAppointments),
      );

      // Return top 10 or less if there are fewer patients
      return patientStats.take(10).toList();
    } catch (e) {
      print('Error getting top patients by cancelled appointments: $e');
      throw ServerException(e.toString());
    }
  }

  Future<Map<String, int>> _getAppointmentsPerDayFromFirestore() async {
    try {
      // Get appointments for the last 7 days
      final DateTime now = DateTime.now();
      final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

      final appointmentQuery =
          await firestore
              .collection('rendez_vous')
              .where(
                'startTime',
                isGreaterThanOrEqualTo: sevenDaysAgo.toIso8601String(),
              )
              .get();

      final appointments = appointmentQuery.docs;

      // Group by day
      Map<String, int> result = {};

      // Initialize with past 7 days
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayKey =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        result[dayKey] = 0;
      }

      // Count appointments per day
      for (var appointment in appointments) {
        final appointmentData = appointment.data();
        final startTimeString = appointmentData['startTime'] as String;
        final date = DateTime.parse(startTimeString);
        final dayKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        if (result.containsKey(dayKey)) {
          result[dayKey] = (result[dayKey] ?? 0) + 1;
        }
      }

      return result;
    } catch (e) {
      print('Error getting appointments per day: $e');
      // Return empty data if error
      final DateTime now = DateTime.now();
      Map<String, int> result = {};
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayKey =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        result[dayKey] = 0;
      }
      return result;
    }
  }

  Future<Map<String, int>> _getAppointmentsPerMonthFromFirestore() async {
    try {
      // Get appointments for the last 12 months
      final DateTime now = DateTime.now();
      final DateTime twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);

      final appointmentQuery =
          await firestore
              .collection('rendez_vous')
              .where(
                'startTime',
                isGreaterThanOrEqualTo: twelveMonthsAgo.toIso8601String(),
              )
              .get();

      final appointments = appointmentQuery.docs;

      // Group by month
      Map<String, int> result = {};

      // Initialize with past 12 months
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        result[monthKey] = 0;
      }

      // Count appointments per month
      for (var appointment in appointments) {
        final appointmentData = appointment.data();
        final startTimeString = appointmentData['startTime'] as String;
        final date = DateTime.parse(startTimeString);
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';

        if (result.containsKey(monthKey)) {
          result[monthKey] = (result[monthKey] ?? 0) + 1;
        }
      }

      return result;
    } catch (e) {
      print('Error getting appointments per month: $e');
      // Return empty data if error
      final DateTime now = DateTime.now();
      Map<String, int> result = {};
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        result[monthKey] = 0;
      }
      return result;
    }
  }

  Future<Map<String, int>> _getAppointmentsPerYearFromFirestore() async {
    try {
      // Get appointments for the last 5 years
      final DateTime now = DateTime.now();
      final DateTime fiveYearsAgo = DateTime(now.year - 5, 1, 1);

      final appointmentQuery =
          await firestore
              .collection('rendez_vous')
              .where(
                'startTime',
                isGreaterThanOrEqualTo: fiveYearsAgo.toIso8601String(),
              )
              .get();

      final appointments = appointmentQuery.docs;

      // Group by year
      Map<String, int> result = {};

      // Initialize with past 5 years
      for (int i = 4; i >= 0; i--) {
        final year = now.year - i;
        result[year.toString()] = 0;
      }

      // Count appointments per year
      for (var appointment in appointments) {
        final appointmentData = appointment.data();
        final startTimeString = appointmentData['startTime'] as String;
        final date = DateTime.parse(startTimeString);
        final yearKey = date.year.toString();

        if (result.containsKey(yearKey)) {
          result[yearKey] = (result[yearKey] ?? 0) + 1;
        }
      }

      return result;
    } catch (e) {
      print('Error getting appointments per year: $e');
      // Return empty data if error
      final DateTime now = DateTime.now();
      Map<String, int> result = {};
      for (int i = 4; i >= 0; i--) {
        final year = now.year - i;
        result[year.toString()] = 0;
      }
      return result;
    }
  }
}
