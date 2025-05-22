import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../domain/entities/rendez_vous_entity.dart';

class PatientProfilePage extends StatefulWidget {
  final PatientEntity patient;
  final List<RendezVousEntity>? pastAppointments;

  const PatientProfilePage({
    Key? key,
    required this.patient,
    this.pastAppointments,
  }) : super(key: key);

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  bool _isLoading = true;
  List<RendezVousEntity> _pastAppointments = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    if (widget.pastAppointments != null) {
      setState(() {
        _pastAppointments = widget.pastAppointments!;
        _isLoading = false;
      });
    } else if (widget.patient.id != null) {
      _loadPatientAppointments();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPatientAppointments() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('rendez_vous')
              .where('patientId', isEqualTo: widget.patient.id)
              .where('status', whereIn: ['completed', 'cancelled'])
              .orderBy('startTime', descending: true)
              .limit(10)
              .get();

      final appointments =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return RendezVousEntity(
              id: doc.id,
              patientId: data['patientId'],
              doctorId: data['doctorId'],
              patientName: data['patientName'],
              doctorName: data['doctorName'],
              speciality: data['speciality'],
              startTime:
                  (data['startTime'] is Timestamp)
                      ? (data['startTime'] as Timestamp).toDate()
                      : DateTime.parse(data['startTime']),
              endTime:
                  data['endTime'] != null
                      ? (data['endTime'] is Timestamp)
                          ? (data['endTime'] as Timestamp).toDate()
                          : DateTime.parse(data['endTime'])
                      : null,
              status: data['status'],
            );
          }).toList();

      setState(() {
        _pastAppointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patient appointments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profil du patient",
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient header card with basic info
            _buildPatientHeaderCard(),

            // Medical History section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                "Informations médicales",
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            _buildMedicalHistoryCard(),

            // Emergency Contact section (if available)
            _buildEmergencyContactCard(),

            // Past Appointments
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Text(
                "Consultations précédentes",
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Appointments list
            _isLoading
                ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
                : _buildPastAppointmentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeaderCard() {
    return Card(
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 70.h,
                  width: 70.w,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 40.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.patient.name} ${widget.patient.lastName}",
                        style: GoogleFonts.raleway(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.patient.dateOfBirth != null
                            ? "${_calculateAge(widget.patient.dateOfBirth!)} ans"
                            : "Âge non spécifié",
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 30.h, thickness: 1),

            // Contact info
            Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  widget.patient.email,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.phone_outlined, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  widget.patient.phoneNumber,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.orange,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  widget.patient.dateOfBirth != null
                      ? DateFormat(
                        'dd/MM/yyyy',
                      ).format(widget.patient.dateOfBirth!)
                      : "Date de naissance non spécifiée",
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  widget.patient.gender,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  color: Colors.red,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    "Informations médicales",
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),

            // Medical history
            Text(
              "Antécédents médicaux:",
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.patient.antecedent.isNotEmpty
                  ? widget.patient.antecedent
                  : "no_medical_history".tr,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            SizedBox(height: 16.h),

            // Blood type
            if (widget.patient.bloodType != null) ...[
              Row(
                children: [
                  Icon(Icons.bloodtype, color: Colors.red, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "blood_type".tr + ": ",
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    widget.patient.bloodType!,
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],

            // Height and weight
            if (widget.patient.height != null ||
                widget.patient.weight != null) ...[
              Row(
                children: [
                  if (widget.patient.height != null) ...[
                    Icon(Icons.height, color: Colors.blue, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "height".tr + ": ",
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "${widget.patient.height!.toString()} cm",
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  SizedBox(width: 16.w),
                  if (widget.patient.weight != null) ...[
                    Icon(Icons.monitor_weight, color: Colors.blue, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "weight".tr + ": ",
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "${widget.patient.weight!.toString()} kg",
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8.h),
            ],

            // Allergies
            if (widget.patient.allergies != null &&
                widget.patient.allergies!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "allergies".tr + ": ",
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.patient.allergies!.join(", "),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    if (widget.patient.emergencyContact == null ||
        (widget.patient.emergencyContact!['name'] == null &&
            widget.patient.emergencyContact!['phoneNumber'] == null)) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            "emergency_contact".tr,
            style: GoogleFonts.raleway(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        Card(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.patient.emergencyContact!['name'] != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.green, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "emergency_contact_name".tr + ": ",
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.patient.emergencyContact!['name']!,
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],

                if (widget.patient.emergencyContact!['relationship'] !=
                    null) ...[
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.green, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "emergency_relationship".tr + ": ",
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.patient.emergencyContact!['relationship']!,
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],

                if (widget.patient.emergencyContact!['phoneNumber'] !=
                    null) ...[
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.green, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "emergency_phone".tr + ": ",
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.patient.emergencyContact!['phoneNumber']!,
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPastAppointmentsList() {
    if (_pastAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 40.sp,
                color: Colors.grey.withOpacity(0.7),
              ),
              SizedBox(height: 16.h),
              Text(
                "no_previous_consultations".tr,
                style: GoogleFonts.raleway(fontSize: 16.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: _pastAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _pastAppointments[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dr. ${appointment.doctorName ?? 'doctor_not_assigned'.tr}",
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            appointment.speciality ??
                                "specialty_not_specified".tr,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          appointment.status,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _getStatusText(appointment.status),
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(appointment.status),
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 24.h),
                Row(
                  children: [
                    Icon(Icons.event, size: 18.sp, color: Colors.grey.shade600),
                    SizedBox(width: 6.w),
                    Text(
                      DateFormat('dd/MM/yyyy').format(appointment.startTime),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Icon(
                      Icons.access_time,
                      size: 18.sp,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      DateFormat('HH:mm').format(appointment.startTime),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    final monthDiff = currentDate.month - birthDate.month;

    if (monthDiff < 0 || (monthDiff == 0 && currentDate.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "completed":
        return Colors.green;
      case "accepted":
        return Colors.blue;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "completed":
        return "status_completed".tr;
      case "accepted":
        return "status_confirmed".tr;
      case "pending":
        return "status_pending".tr;
      case "cancelled":
        return "status_cancelled".tr;
      default:
        return "status_unknown".tr;
    }
  }
}
