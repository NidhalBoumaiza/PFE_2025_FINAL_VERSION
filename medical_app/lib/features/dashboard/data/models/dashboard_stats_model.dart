import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/dashboard_stats_entity.dart';

class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    required int totalPatients,
    required int totalAppointments,
    required int pendingAppointments,
    required int completedAppointments,
    required int cancelledAppointments,
    required List<AppointmentEntity> upcomingAppointments,
  }) : super(
          totalPatients: totalPatients,
          totalAppointments: totalAppointments,
          pendingAppointments: pendingAppointments,
          completedAppointments: completedAppointments,
          cancelledAppointments: cancelledAppointments,
          upcomingAppointments: upcomingAppointments,
        );

  factory DashboardStatsModel.fromFirestore({
    required int totalPatients,
    required int totalAppointments,
    required int pendingAppointments,
    required int completedAppointments,
    required int cancelledAppointments,
    required List<AppointmentModel> upcomingAppointments,
  }) {
    return DashboardStatsModel(
      totalPatients: totalPatients,
      totalAppointments: totalAppointments,
      pendingAppointments: pendingAppointments,
      completedAppointments: completedAppointments,
      cancelledAppointments: cancelledAppointments,
      upcomingAppointments: upcomingAppointments,
    );
  }
}

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required String id,
    required String patientId,
    required String patientName,
    required DateTime appointmentDate,
    required String status,
    String? appointmentType,
  }) : super(
          id: id,
          patientId: patientId,
          patientName: patientName,
          appointmentDate: appointmentDate,
          status: status,
          appointmentType: appointmentType,
        );

  factory AppointmentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime appointmentDate;
    try {
      if (data['startTime'] is Timestamp) {
        appointmentDate = (data['startTime'] as Timestamp).toDate();
      } else if (data['startTime'] is String) {
        // Try to parse the string as a DateTime
        appointmentDate = DateTime.parse(data['startTime'] as String);
      } else {
        // Default to current time if field is missing or invalid
        appointmentDate = DateTime.now();
      }
    } catch (e) {
      // Handle any parsing errors by using current time
      print('Error parsing date: $e');
      appointmentDate = DateTime.now();
    }

    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown Patient',
      appointmentDate: appointmentDate,
      status: data['status'] ?? 'pending',
      appointmentType: data['appointmentType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'startTime': Timestamp.fromDate(appointmentDate),
      'status': status,
      if (appointmentType != null) 'appointmentType': appointmentType,
    };
  }
} 