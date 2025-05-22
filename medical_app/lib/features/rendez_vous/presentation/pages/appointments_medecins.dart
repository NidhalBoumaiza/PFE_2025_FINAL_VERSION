import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../features/authentication/data/models/user_model.dart';
import '../../../../features/authentication/data/models/medecin_model.dart';
import '../../../../features/authentication/domain/entities/medecin_entity.dart';
import '../../../../features/authentication/domain/entities/patient_entity.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/rendez_vous_entity.dart';
import '../blocs/rendez-vous BLoC/rendez_vous_bloc.dart';
import 'appointment_details_page.dart';
import '../../../rendez_vous/presentation/pages/patient_profile_page.dart';

class AppointmentsMedecins extends StatefulWidget {
  final DateTime? initialSelectedDate;
  final String? initialFilter;
  final bool showAppBar;

  const AppointmentsMedecins({
    Key? key,
    this.initialSelectedDate,
    this.initialFilter,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  _AppointmentsMedecinsState createState() => _AppointmentsMedecinsState();
}

class _AppointmentsMedecinsState extends State<AppointmentsMedecins> {
  late RendezVousBloc _rendezVousBloc;
  UserModel? currentUser;
  List<RendezVousEntity> appointments = [];
  List<RendezVousEntity> filteredAppointments = [];

  bool isLoading = true;
  Map<String, bool> updatingAppointments = {};
  DateTime? selectedDate;
  String? statusFilter;
  bool isCalendarVisible = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _rendezVousBloc = di.sl<RendezVousBloc>();
    // Set both filters to null initially regardless of widget parameters
    selectedDate = null;
    statusFilter = null;
    _loadUser();

    // Debug the initial filter
    print('Initial filters cleared. No filters applied on startup.');
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('CACHED_USER');

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          currentUser = UserModel.fromJson(userMap);
        });

        // Fetch appointments using the doctor ID
        if (currentUser != null && currentUser!.id != null) {
          // Check for past appointments that need to be updated to completed
          _rendezVousBloc.add(
            CheckAndUpdatePastAppointments(
              userId: currentUser!.id!,
              userRole: 'doctor',
            ),
          );

          // Then fetch the appointments (which will now have updated statuses)
          _rendezVousBloc.add(FetchRendezVous(doctorId: currentUser!.id));
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "patient_info_unavailable".tr,
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
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to filter appointments by date
  void _applyDateFilter() {
    filteredAppointments = List.from(appointments);

    print('Filtering ${appointments.length} appointments...');
    print('Current status filter: $statusFilter');

    // Apply date filter if selected
    if (selectedDate != null) {
      filteredAppointments =
          filteredAppointments.where((appointment) {
            final appointmentDate = DateFormat(
              'yyyy-MM-dd',
            ).format(appointment.startTime);
            final filterDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
            return appointmentDate == filterDate;
          }).toList();

      print('After date filter: ${filteredAppointments.length} appointments');
    }

    // Apply status filter if selected
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      filteredAppointments =
          filteredAppointments.where((appointment) {
            final matches = appointment.status == statusFilter;
            print(
              'Checking appointment ${appointment.id}: status=${appointment.status}, filter=$statusFilter, matches=$matches',
            );
            return matches;
          }).toList();

      print('After status filter: ${filteredAppointments.length} appointments');
    }
  }

  // Reset filters
  void _resetFilter() {
    setState(() {
      selectedDate = null;
      statusFilter = null;
      filteredAppointments = List.from(appointments);
    });
  }

  void _applyStatusFilter(String status) {
    setState(() {
      statusFilter = status;
      _applyDateFilter();
    });
  }

  // Update appointment status
  void _updateAppointmentStatus(
    RendezVousEntity appointment,
    String newStatus,
  ) {
    if (appointment.id == null ||
        appointment.patientId == null ||
        appointment.doctorId == null ||
        appointment.patientName == null ||
        appointment.doctorName == null ||
        currentUser == null) {
      return;
    }

    setState(() {
      updatingAppointments[appointment.id!] = true;
    });

    // Debug print to confirm the update is being triggered
    print('Updating appointment ${appointment.id} status to $newStatus');

    _rendezVousBloc.add(
      UpdateRendezVousStatus(
        rendezVousId: appointment.id!,
        status: newStatus,
        patientId: appointment.patientId!,
        doctorId: appointment.doctorId!,
        patientName: appointment.patientName!,
        doctorName: appointment.doctorName!,
      ),
    );
  }

  // Show time picker to change appointment time
  Future<void> _showTimePicker(RendezVousEntity appointment) async {
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(appointment.startTime);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Create new appointment with updated time
      final DateTime newDateTime = DateTime(
        appointment.startTime.year,
        appointment.startTime.month,
        appointment.startTime.day,
        picked.hour,
        picked.minute,
      );

      // Calculate new end time based on doctor's appointment duration
      int appointmentDuration = 30; // Default
      if (currentUser != null && currentUser is MedecinModel) {
        appointmentDuration = (currentUser as MedecinModel).appointmentDuration;
      }

      final DateTime newEndTime = newDateTime.add(
        Duration(minutes: appointmentDuration),
      );

      // Create new appointment object with updated time
      final updatedAppointment = RendezVousEntity(
        id: appointment.id,
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        patientName: appointment.patientName,
        doctorName: appointment.doctorName,
        speciality: appointment.speciality,
        startTime: newDateTime,
        endTime: newEndTime,
        status: appointment.status,
      );

      // TODO: Add support for updating appointment time
      // For now show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "La fonctionnalité de modification d'heure sera disponible prochainement",
            style: GoogleFonts.raleway(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Fetch patient info from Firestore
  Future<PatientEntity?> _fetchPatientInfo(String patientId) async {
    try {
      final patientDoc =
          await _firestore.collection('patients').doc(patientId).get();

      if (patientDoc.exists) {
        Map<String, dynamic> patientData =
            patientDoc.data() as Map<String, dynamic>;
        return PatientEntity(
          id: patientId,
          name: patientData['name'] ?? '',
          lastName: patientData['lastName'] ?? '',
          email: patientData['email'] ?? '',
          role: 'patient',
          gender: patientData['gender'] ?? 'unknown',
          phoneNumber: patientData['phoneNumber'] ?? '',
          dateOfBirth:
              patientData['dateOfBirth'] != null
                  ? (patientData['dateOfBirth'] is Timestamp)
                      ? (patientData['dateOfBirth'] as Timestamp).toDate()
                      : DateTime.tryParse(patientData['dateOfBirth'])
                  : null,
          antecedent: patientData['antecedent'] as String? ?? '',
        );
      }
      return null;
    } catch (e) {
      print('Error fetching patient info: $e');
      return null;
    }
  }

  // Navigate to patient profile
  void _navigateToPatientProfile(RendezVousEntity appointment) async {
    if (appointment.patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "patient_info_unavailable".tr,
            style: GoogleFonts.raleway(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
    );

    try {
      // Try to fetch patient from Firestore
      PatientEntity? patientEntity = await _fetchPatientInfo(
        appointment.patientId!,
      );

      // Dismiss loading indicator
      Navigator.pop(context);

      // If fetch failed, create a basic patient entity with available info
      if (patientEntity == null) {
        final nameArray =
            appointment.patientName?.split(' ') ?? ['Patient', 'Inconnu'];
        final firstName = nameArray.isNotEmpty ? nameArray[0] : '';
        final lastName = nameArray.length > 1 ? nameArray[1] : '';

        patientEntity = PatientEntity(
          id: appointment.patientId!,
          name: firstName,
          lastName: lastName,
          email: "patient@medical-app.com",
          role: 'patient',
          gender: 'unknown',
          phoneNumber: "",
          dateOfBirth: null,
          antecedent: "",
        );
      }

      // Navigate to patient profile page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientProfilePage(patient: patientEntity!),
        ),
      );
    } catch (e) {
      // Handle any errors
      Navigator.pop(context); // Dismiss loading indicator if error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "error_loading_profile".trParams({'0': e.toString()}),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Text(
                  "appointments".tr,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primaryColor,
                elevation: 2,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  // Calendar button for date selection
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isCalendarVisible = !isCalendarVisible;
                      });
                    },
                  ),
                ],
              )
              : null,
      body: BlocProvider.value(
        value: _rendezVousBloc,
        child: BlocConsumer<RendezVousBloc, RendezVousState>(
          listener: (context, state) {
            print('Current state: ${state.runtimeType}');

            if (state is RendezVousLoaded) {
              print('Loaded ${state.rendezVous.length} appointments');

              // Debug the appointments statuses
              for (var appt in state.rendezVous) {
                print('Appointment ${appt.id}: status=${appt.status}');
              }

              setState(() {
                appointments = state.rendezVous;
                isLoading = false;

                // Apply filters after setting appointments
                _applyDateFilter();
              });

              // Debug information about initial filters
              if (widget.initialFilter != null) {
                print('Initial filter was set: ${widget.initialFilter}');
                print('Current status filter: $statusFilter');
              }

              print(
                'Filtered appointments count: ${filteredAppointments.length}',
              );
            } else if (state is RendezVousStatusUpdatedState) {
              print(
                'Status updated for appointment ${state.id} to ${state.status}',
              );

              setState(() {
                updatingAppointments.remove(state.id);

                // Update the appointment status in the local list
                if (appointments.isNotEmpty) {
                  final index = appointments.indexWhere(
                    (appt) => appt.id == state.id,
                  );
                  if (index != -1) {
                    // Create a new updated appointment with the new status
                    final updatedAppointment = RendezVousEntity(
                      id: appointments[index].id,
                      patientId: appointments[index].patientId,
                      doctorId: appointments[index].doctorId,
                      patientName: appointments[index].patientName,
                      doctorName: appointments[index].doctorName,
                      startTime: appointments[index].startTime,
                      endTime: appointments[index].endTime,
                      speciality: appointments[index].speciality,
                      status: state.status,
                    );

                    appointments[index] = updatedAppointment;
                    _applyDateFilter(); // Re-apply filters to update the UI
                  }
                }
              });

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.status == 'accepted'
                        ? "appointment_accepted".tr
                        : "appointment_rejected".tr,
                    style: GoogleFonts.raleway(),
                  ),
                  backgroundColor:
                      state.status == 'accepted' ? Colors.green : Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is UpdatingRendezVousState) {
              // We're already showing the loading indicator via updatingAppointments
              print('Updating appointment status...');
            } else if (state is RendezVousError) {
              setState(() {
                isLoading = false;
                updatingAppointments.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: GoogleFonts.raleway()),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Animated Calendar Container
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: isCalendarVisible ? 350.h : 0,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCalendarVisible)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Calendar header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Sélectionner une date",
                                      style: GoogleFonts.raleway(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (selectedDate != null)
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedDate = null;
                                                isCalendarVisible = false;
                                              });
                                              _applyDateFilter();
                                            },
                                            child: Text(
                                              "Effacer",
                                              style: GoogleFonts.raleway(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              isCalendarVisible = false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // The Calendar
                                TableCalendar(
                                  firstDay: DateTime.now().subtract(
                                    Duration(days: 365),
                                  ),
                                  lastDay: DateTime.now().add(
                                    Duration(days: 365),
                                  ),
                                  focusedDay: selectedDate ?? DateTime.now(),
                                  calendarFormat: _calendarFormat,
                                  onFormatChanged: (format) {
                                    setState(() {
                                      _calendarFormat = format;
                                    });
                                  },
                                  selectedDayPredicate: (day) {
                                    return selectedDate != null &&
                                        isSameDay(selectedDate!, day);
                                  },
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      selectedDate = selectedDay;
                                      isCalendarVisible = false;
                                    });
                                    _applyDateFilter();
                                  },
                                  // Event indicators with count
                                  calendarBuilders: CalendarBuilders(
                                    markerBuilder: (context, date, events) {
                                      // Count appointments on this day
                                      final appointmentsOnDay =
                                          appointments.where((appointment) {
                                            return isSameDay(
                                              appointment.startTime,
                                              date,
                                            );
                                          }).toList();

                                      if (appointmentsOnDay.isEmpty) {
                                        return null;
                                      }

                                      return Positioned(
                                        bottom: 1,
                                        right: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primaryColor,
                                          ),
                                          width: 16.w,
                                          height: 16.h,
                                          child: Center(
                                            child: Text(
                                              '${appointmentsOnDay.length}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  calendarStyle: CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  headerStyle: HeaderStyle(
                                    formatButtonTextStyle: GoogleFonts.raleway(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor,
                                    ),
                                    titleTextStyle: GoogleFonts.raleway(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    leftChevronIcon: Icon(
                                      Icons.chevron_left,
                                      color: AppColors.primaryColor,
                                    ),
                                    rightChevronIcon: Icon(
                                      Icons.chevron_right,
                                      color: AppColors.primaryColor,
                                    ),
                                    formatButtonVisible: true,
                                    titleCentered: true,
                                  ),
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: 'Mois',
                                    CalendarFormat.twoWeeks: '2 Semaines',
                                    CalendarFormat.week: 'Semaine',
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (selectedDate != null || statusFilter != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    color: AppColors.primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          color: AppColors.primaryColor,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            selectedDate != null
                                ? "filtered_by_date".trParams({
                                  '0': DateFormat(
                                    'dd MMMM yyyy',
                                  ).format(selectedDate!),
                                })
                                : statusFilter != null
                                ? "${'filters'.tr}: ${_getStatusText(statusFilter!)}"
                                : "filters".tr,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _resetFilter,
                          child: Icon(
                            Icons.close,
                            color: AppColors.primaryColor,
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Status filter chips
                Container(
                  height: 50.h,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('all'.tr, null),
                      SizedBox(width: 8.w),
                      _buildFilterChip('status_pending'.tr, 'pending'),
                      SizedBox(width: 8.w),
                      _buildFilterChip('status_confirmed'.tr, 'accepted'),
                      SizedBox(width: 8.w),
                      _buildFilterChip('status_completed'.tr, 'completed'),
                      SizedBox(width: 8.w),
                      _buildFilterChip('status_cancelled'.tr, 'cancelled'),
                    ],
                  ),
                ),

                Expanded(
                  child:
                      isLoading
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  "loading_appointments".tr,
                                  style: GoogleFonts.raleway(
                                    fontSize: 16.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                          : filteredAppointments.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: 64.sp,
                                    color: Colors.grey.withOpacity(0.7),
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  selectedDate != null
                                      ? "Aucun rendez-vous trouvé pour cette date"
                                      : statusFilter != null
                                      ? "Aucun rendez-vous ${_getStatusText(statusFilter!).toLowerCase()}"
                                      : "Aucun rendez-vous trouvé",
                                  style: GoogleFonts.raleway(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "Essayez de modifier les filtres ou d'actualiser la page",
                                  style: GoogleFonts.raleway(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                          : RefreshIndicator(
                            onRefresh: () async {
                              if (currentUser != null &&
                                  currentUser!.id != null) {
                                _rendezVousBloc.add(
                                  FetchRendezVous(doctorId: currentUser!.id),
                                );
                              }
                            },
                            color: AppColors.primaryColor,
                            child: ListView.builder(
                              padding: EdgeInsets.all(16.w),
                              itemCount: filteredAppointments.length,
                              itemBuilder: (context, index) {
                                final appointment = filteredAppointments[index];
                                final isUpdating =
                                    appointment.id != null &&
                                    updatingAppointments[appointment.id] ==
                                        true;
                                final formattedDate = DateFormat(
                                  'dd/MM/yyyy',
                                ).format(appointment.startTime);
                                final formattedTime = DateFormat(
                                  'HH:mm',
                                ).format(appointment.startTime);

                                return Card(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: InkWell(
                                    onTap:
                                        appointment.id != null
                                            ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          AppointmentDetailsPage(
                                                            appointment:
                                                                appointment,
                                                          ),
                                                ),
                                              );
                                            }
                                            : null,
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Padding(
                                      padding: EdgeInsets.all(16.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 50.h,
                                                width: 50.w,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                ),
                                                child: InkWell(
                                                  onTap:
                                                      () =>
                                                          _navigateToPatientProfile(
                                                            appointment,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 30.sp,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 16.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    InkWell(
                                                      onTap:
                                                          () =>
                                                              _navigateToPatientProfile(
                                                                appointment,
                                                              ),
                                                      child: Text(
                                                        appointment
                                                                .patientName ??
                                                            "Patient inconnu",
                                                        style:
                                                            GoogleFonts.raleway(
                                                              fontSize: 16.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      "$formattedDate à $formattedTime",
                                                      style:
                                                          GoogleFonts.raleway(
                                                            fontSize: 14.sp,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade600,
                                                          ),
                                                    ),
                                                    SizedBox(height: 8.h),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    10.w,
                                                                vertical: 4.h,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                _getStatusColor(
                                                                  appointment
                                                                      .status,
                                                                ).withOpacity(
                                                                  0.2,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20.r,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            _getStatusText(
                                                              appointment
                                                                  .status,
                                                            ),
                                                            style: GoogleFonts.raleway(
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  _getStatusColor(
                                                                    appointment
                                                                        .status,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                        if (appointment
                                                                .speciality !=
                                                            null)
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  left: 8.w,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        10.w,
                                                                    vertical:
                                                                        4.h,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .blue
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      20.r,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                appointment
                                                                    .speciality!,
                                                                style: GoogleFonts.raleway(
                                                                  fontSize:
                                                                      12.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      Colors
                                                                          .blue,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (appointment.status == "pending")
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 16.h,
                                              ),
                                              child: Wrap(
                                                spacing: 8.w,
                                                runSpacing: 8.h,
                                                alignment: WrapAlignment.end,
                                                children: [
                                                  OutlinedButton.icon(
                                                    onPressed:
                                                        isUpdating
                                                            ? null
                                                            : () =>
                                                                _showTimePicker(
                                                                  appointment,
                                                                ),
                                                    icon: Icon(
                                                      Icons.access_time,
                                                      size: 18.sp,
                                                      color: Colors.blue,
                                                    ),
                                                    label: Text(
                                                      "modify_time".tr,
                                                      style:
                                                          GoogleFonts.raleway(
                                                            fontSize: 12.sp,
                                                            color: Colors.blue,
                                                          ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      side: BorderSide(
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade300,
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12.w,
                                                            vertical: 6.h,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8.r,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        isUpdating
                                                            ? null
                                                            : () =>
                                                                _updateAppointmentStatus(
                                                                  appointment,
                                                                  "accepted",
                                                                ),
                                                    icon:
                                                        isUpdating
                                                            ? SizedBox(
                                                              height: 16.sp,
                                                              width: 16.sp,
                                                              child: CircularProgressIndicator(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                strokeWidth:
                                                                    2.w,
                                                              ),
                                                            )
                                                            : Icon(
                                                              Icons.check,
                                                              size: 18.sp,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                    label: Text(
                                                      "accept".tr,
                                                      style:
                                                          GoogleFonts.raleway(
                                                            fontSize: 12.sp,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12.w,
                                                            vertical: 6.h,
                                                          ),
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8.r,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        isUpdating
                                                            ? null
                                                            : () =>
                                                                _updateAppointmentStatus(
                                                                  appointment,
                                                                  "cancelled",
                                                                ),
                                                    icon: Icon(
                                                      Icons.close,
                                                      size: 18.sp,
                                                      color: Colors.white,
                                                    ),
                                                    label: Text(
                                                      "reject".tr,
                                                      style:
                                                          GoogleFonts.raleway(
                                                            fontSize: 12.sp,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12.w,
                                                            vertical: 6.h,
                                                          ),
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8.r,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = status == statusFilter;

    return GestureDetector(
      onTap: () {
        print('Filter chip tapped: $label, status: $status');
        setState(() {
          statusFilter = status;
          _applyDateFilter();
        });
        print('After setting filter - statusFilter: $statusFilter');
        print('Filtered appointments: ${filteredAppointments.length}');
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'status_pending'.tr;
      case 'accepted':
        return 'status_confirmed'.tr;
      case 'cancelled':
        return 'status_cancelled'.tr;
      case 'completed':
        return 'status_completed'.tr;
      default:
        return 'status_unknown'.tr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      case "completed":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    // Don't close the BLoC here as it might be provided by the dependency injection
    super.dispose();
  }
}
