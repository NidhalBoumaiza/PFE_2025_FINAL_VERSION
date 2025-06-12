import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../domain/entities/rendez_vous_entity.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../dossier_medical/presentation/bloc/dossier_medical_bloc.dart';
import '../../../dossier_medical/presentation/bloc/dossier_medical_event.dart';
import '../../../dossier_medical/presentation/bloc/dossier_medical_state.dart';
import '../../../dossier_medical/presentation/pages/dossier_medical_screen.dart';
import '../../../../injection_container.dart' as di;
import '../../../../core/utils/navigation_with_transition.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<RendezVousEntity> pastAppointments = [];
  bool isLoading = true;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPastAppointments();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('CACHED_USER');
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          currentUser = UserModel.fromJson(userMap);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadPastAppointments() async {
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
        pastAppointments = appointments;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading patient appointments: $e');
      setState(() {
        isLoading = false;
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

            // Medical Files section - only show if doctor has access
            if (currentUser != null &&
                currentUser!.role == 'medecin' &&
                widget.patient.id != null)
              _buildMedicalFilesSection(),

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
            isLoading
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
              "Antécédents médicaux" + ":",
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
                  : "Aucun antécédent médical",
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
                    "Groupe sanguin" + ": ",
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
                      "Taille" + ": ",
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
                      "Poids" + ": ",
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
                    "Allergies" + ": ",
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
            "Contact d'urgence",
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
                        "Nom du contact d'urgence" + ": ",
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
                        "Relation d'urgence" + ": ",
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
                        "Téléphone d'urgence" + ": ",
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

  Widget _buildMedicalFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            "Dossier médical",
            style: GoogleFonts.raleway(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        BlocProvider(
          create:
              (context) =>
                  di.sl<DossierMedicalBloc>()..add(
                    FetchDossierMedicalEvent(
                      patientId: widget.patient.id!,
                      doctorId: currentUser?.id,
                    ),
                  ),
          child: BlocBuilder<DossierMedicalBloc, DossierMedicalState>(
            builder: (context, state) {
              if (state is DossierMedicalLoading) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                );
              }

              if (state is DossierMedicalError) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 48.sp,
                          color: Colors.red.shade400,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "Accès refusé",
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Vous n'avez pas l'autorisation d'accéder au dossier médical de ce patient",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is DossierMedicalEmpty) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 48.sp,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "Aucun fichier médical",
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Aucun fichier médical n'a été ajouté pour ce patient",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is DossierMedicalLoaded) {
                return Card(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  color: AppColors.primaryColor,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "Fichiers médicaux",
                                  style: GoogleFonts.raleway(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => BlocProvider(
                                          create:
                                              (context) =>
                                                  di.sl<DossierMedicalBloc>()
                                                    ..add(
                                                      FetchDossierMedicalEvent(
                                                        patientId:
                                                            widget.patient.id!,
                                                        doctorId:
                                                            currentUser?.id,
                                                      ),
                                                    ),
                                          child: DossierMedicalScreen(
                                            patientId: widget.patient.id!,
                                          ),
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  "Voir tout",
                                  style: GoogleFonts.raleway(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "${state.dossier.files.length} fichier(s) disponible(s)",
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // Show first 3 files as preview
                        ...state.dossier.files.take(3).map((file) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getFileIcon(file.mimetype),
                                  color: AppColors.primaryColor,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.originalName,
                                        style: GoogleFonts.raleway(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (file.description.isNotEmpty) ...[
                                        SizedBox(height: 2.h),
                                        Text(
                                          file.description,
                                          style: GoogleFonts.raleway(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yy').format(file.createdAt),
                                  style: GoogleFonts.raleway(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        if (state.dossier.files.length > 3) ...[
                          SizedBox(height: 8.h),
                          Center(
                            child: Text(
                              "et ${state.dossier.files.length - 3} autre(s) fichier(s)...",
                              style: GoogleFonts.raleway(
                                fontSize: 12.sp,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String mimetype) {
    if (mimetype.startsWith('image/')) {
      return Icons.image_outlined;
    } else if (mimetype == 'application/pdf') {
      return Icons.picture_as_pdf_outlined;
    } else {
      return Icons.insert_drive_file_outlined;
    }
  }

  Widget _buildPastAppointmentsList() {
    if (pastAppointments.isEmpty) {
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
                "Aucune consultation précédente",
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
      itemCount: pastAppointments.length,
      itemBuilder: (context, index) {
        final appointment = pastAppointments[index];
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
                            "Dr. ${appointment.doctorName ?? 'Médecin non assigné'}",
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
                                "Spécialité non spécifiée",
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
        return "Terminé";
      case "accepted":
        return "Confirmé";
      case "pending":
        return "En attente";
      case "cancelled":
        return "Annulé";
      default:
        return "Statut inconnu";
    }
  }
}
