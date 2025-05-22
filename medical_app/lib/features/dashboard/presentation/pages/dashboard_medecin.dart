import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/domain/entities/medecin_entity.dart';
import '../../../rendez_vous/domain/entities/rendez_vous_entity.dart';
import '../../../rendez_vous/presentation/pages/RendezVousMedecin.dart';
import '../../../rendez_vous/presentation/pages/appointments_medecins.dart';
import '../../../rendez_vous/presentation/pages/appointment_details_page.dart';
import '../../../rendez_vous/presentation/blocs/rendez-vous BLoC/rendez_vous_bloc.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../blocs/dashboard BLoC/dashboard_bloc.dart';
import '../blocs/dashboard BLoC/dashboard_event.dart';
import '../blocs/dashboard BLoC/dashboard_state.dart';
import '../widgets/appointment_list_item.dart';
import '../widgets/dashboard_stat_card.dart';
import 'doctor_patients_page.dart';

class DashboardMedecin extends StatefulWidget {
  const DashboardMedecin({Key? key}) : super(key: key);

  @override
  State<DashboardMedecin> createState() => _DashboardMedecinState();
}

class _DashboardMedecinState extends State<DashboardMedecin> {
  late DashboardBloc _dashboardBloc;
  late RendezVousBloc _rendezVousBloc;
  UserModel? currentUser;
  MedecinEntity? doctorUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = BlocProvider.of<DashboardBloc>(context);
    _rendezVousBloc = di.sl<RendezVousBloc>();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('CACHED_USER');

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);

        setState(() {
          currentUser = user;
          isLoading = false;
        });

        if (user.id != null) {
          // Fetch dashboard stats
          _dashboardBloc.add(FetchDoctorDashboardStats(doctorId: user.id!));

          // Check and update past appointments
          _rendezVousBloc.add(
            CheckAndUpdatePastAppointments(
              userId: user.id!,
              userRole: 'doctor',
            ),
          );

          // Check if the doctor has appointment duration set
          _checkAppointmentDuration(user.id!);
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'error_loading_user_data'.tr,
            style: GoogleFonts.raleway(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Check if appointment duration is set, if not show dialog
  Future<void> _checkAppointmentDuration(String doctorId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final doctorDoc =
          await firestore.collection('medecins').doc(doctorId).get();

      if (doctorDoc.exists) {
        final data = doctorDoc.data() as Map<String, dynamic>;

        // If appointmentDuration doesn't exist or is null, show dialog
        if (!data.containsKey('appointmentDuration') ||
            data['appointmentDuration'] == null) {
          // Delay showing the dialog slightly to ensure the UI is ready
          Future.delayed(Duration(milliseconds: 500), () {
            _showAppointmentDurationDialog();
          });
        }
      }
    } catch (e) {
      print('Error checking appointment duration: $e');
    }
  }

  // Dialog to set appointment duration
  void _showAppointmentDurationDialog() {
    int selectedDuration = 30; // Default duration

    showDialog(
      context: context,
      barrierDismissible: false, // User must select a duration
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'consultation_duration'.tr,
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'set_consultation_duration'.tr,
                    style: GoogleFonts.raleway(fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'duration'.tr + ': ',
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DropdownButton<int>(
                        value: selectedDuration,
                        items:
                            [15, 20, 30, 45, 60, 90, 120].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                  '$value ' + 'minutes'.tr,
                                  style: GoogleFonts.raleway(fontSize: 16.sp),
                                ),
                              );
                            }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDuration = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Save the selected duration to Firestore
                try {
                  if (currentUser?.id != null) {
                    final FirebaseFirestore firestore =
                        FirebaseFirestore.instance;
                    await firestore
                        .collection('medecins')
                        .doc(currentUser!.id)
                        .update({'appointmentDuration': selectedDuration});

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'consultation_duration_set'.tr.replaceAll(
                            '{0}',
                            selectedDuration.toString(),
                          ),
                          style: GoogleFonts.raleway(),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error saving appointment duration: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'error_saving'.tr.replaceAll('{0}', e.toString()),
                        style: GoogleFonts.raleway(),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'confirm'.tr,
                style: GoogleFonts.raleway(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryColor),
                    SizedBox(height: 16.h),
                    Text(
                      "loading_dashboard".tr,
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  if (currentUser?.id != null) {
                    _dashboardBloc.add(
                      FetchDoctorDashboardStats(doctorId: currentUser!.id!),
                    );
                  }
                },
                color: AppColors.primaryColor,
                child: _buildDashboardContent(),
              ),
    );
  }

  Widget _buildDashboardContent() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
              );
            } else if (state is DashboardError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 100.h),
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 70.sp,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "error_loading".tr,
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      state.message,
                      style: GoogleFonts.raleway(
                        fontSize: 15.sp,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (currentUser?.id != null) {
                        _dashboardBloc.add(
                          FetchDoctorDashboardStats(doctorId: currentUser!.id!),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.refresh, size: 20.sp),
                    label: Text(
                      "retry".tr,
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              );
            }

            // Default stats in case no state is loaded yet
            int totalPatients = 0;
            int totalAppointments = 0;
            int pendingAppointments = 0;
            int completedAppointments = 0;
            List<AppointmentEntity> upcomingAppointments = [];

            if (state is DashboardLoaded) {
              totalPatients = state.dashboardStats.totalPatients;
              totalAppointments = state.dashboardStats.totalAppointments;
              pendingAppointments = state.dashboardStats.pendingAppointments;
              completedAppointments =
                  state.dashboardStats.completedAppointments;
              upcomingAppointments = state.dashboardStats.upcomingAppointments;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Text(
                  "hello_doctor".tr.replaceAll(
                    "{0}",
                    currentUser?.lastName ?? '',
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.headlineMedium?.color,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "day_overview".tr,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 24.h),

                // Stats section
                Text(
                  'statistics'.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                SizedBox(height: 12.h),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.18,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  children: [
                    DashboardStatCard(
                      title: 'patients'.tr,
                      value: totalPatients.toString(),
                      icon: Icons.people,
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorPatientsPage(),
                          ),
                        );
                      },
                    ),
                    DashboardStatCard(
                      title: 'total_appointments'.tr,
                      value: totalAppointments.toString(),
                      icon: Icons.calendar_month,
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentsMedecins(),
                          ),
                        );
                      },
                    ),
                    DashboardStatCard(
                      title: 'pending_appointments'.tr,
                      value: pendingAppointments.toString(),
                      icon: Icons.schedule,
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const AppointmentsMedecins(
                                  initialFilter: 'pending',
                                ),
                          ),
                        );
                      },
                    ),
                    DashboardStatCard(
                      title: 'completed_appointments'.tr,
                      value: completedAppointments.toString(),
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const AppointmentsMedecins(
                                  initialFilter: 'completed',
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Quick actions
                Text(
                  'quick_actions'.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        "view_all_appointments".tr,
                        Icons.list_alt,
                        AppColors.primaryColor,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentsMedecins(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        "emergencies".tr,
                        Icons.warning,
                        Colors.red,
                        () {
                          // Navigate to a different page or show a message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'emergency_feature_development'.tr,
                                style: GoogleFonts.raleway(),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Upcoming appointments section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'upcoming_appointments'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentsMedecins(),
                          ),
                        );
                      },
                      child: Text(
                        'see_all'.tr,
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                if (state is DashboardLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                else if (upcomingAppointments.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48.sp,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.6,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'no_upcoming_appointments'.tr,
                              style: GoogleFonts.raleway(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.titleMedium?.color,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'pending_appointments_will_appear_here'.tr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (currentUser?.id != null) {
                                  _dashboardBloc.add(
                                    FetchDoctorDashboardStats(
                                      doctorId: currentUser!.id!,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 10.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(Icons.refresh, size: 20.sp),
                              label: Text(
                                "retry".tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children:
                            upcomingAppointments.map((appointment) {
                              return Column(
                                children: [
                                  _buildAppointmentCard(appointment),
                                  if (appointment != upcomingAppointments.last)
                                    Divider(height: 16.h),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),

                SizedBox(height: 24.h),

                //   SizedBox(height: 24.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          Icon(icon, color: Colors.white),
          Text(
            title,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  RendezVousEntity _convertToRendezVous(AppointmentEntity appointment) {
    return RendezVousEntity(
      id: appointment.id,
      patientId: appointment.patientId,
      doctorId: currentUser?.id,
      patientName: appointment.patientName,
      doctorName:
          currentUser != null ? "Dr. ${currentUser!.lastName}" : "Doctor",
      speciality: appointment.appointmentType,
      startTime: appointment.appointmentDate,
      endTime: appointment.appointmentDate.add(const Duration(minutes: 30)),
      status: appointment.status,
    );
  }

  Widget _buildAppointmentCard(AppointmentEntity appointment) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Format the date in a more readable format
    final formattedDate =
        appointment.appointmentDate.day.toString().padLeft(2, '0') +
        '/' +
        appointment.appointmentDate.month.toString().padLeft(2, '0') +
        '/' +
        appointment.appointmentDate.year.toString();
    final formattedTime =
        appointment.appointmentDate.hour.toString().padLeft(2, '0') +
        ':' +
        appointment.appointmentDate.minute.toString().padLeft(2, '0');

    // Get an appropriate color for the status badge
    Color statusColor;
    switch (appointment.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AppointmentDetailsPage(
                    appointment: _convertToRendezVous(appointment),
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient avatar
              Container(
                height: 50.h,
                width: 50.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.person, color: Colors.white, size: 30.sp),
              ),
              SizedBox(width: 16.w),

              // Appointment details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      appointment.appointmentType ?? 'Consultation',
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 8.h,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16.sp,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              formattedDate,
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16.sp,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              formattedTime,
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: GoogleFonts.raleway(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
