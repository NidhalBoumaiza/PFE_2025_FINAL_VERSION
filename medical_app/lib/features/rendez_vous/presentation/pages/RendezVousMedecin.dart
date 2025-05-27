import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/injection_container.dart';
import 'package:medical_app/widgets/reusable_text_widget.dart';

class RendezVousMedecin extends StatefulWidget {
  const RendezVousMedecin({super.key});

  @override
  State<RendezVousMedecin> createState() => _RendezVousMedecinState();
}

class _RendezVousMedecinState extends State<RendezVousMedecin> {
  String? doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final authLocalDataSource = sl<AuthLocalDataSource>();
    final user = await authLocalDataSource.getUser();
    setState(() {
      doctorId = user.id;
    });
    if (doctorId != null) {
      context.read<RendezVousBloc>().add(FetchRendezVous(doctorId: doctorId));
    }
  }

  Future<bool?> _showConfirmationDialog(
    String action,
    String patientName,
  ) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('confirm_consultation'.tr),
        content: Text(
              'confirm_action_consultation'.tr
                  .replaceAll('{action}', action)
                  .replaceAll('{patient}', patientName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
                child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  void _updateConsultationStatus(
      String id,
      String newStatus,
      String patientName,
      String patientId,
      String doctorId,
      String doctorName,
      ) async {
    final action = newStatus == 'accepted' ? 'accept'.tr : 'refuse'.tr;
    final confirmed = await _showConfirmationDialog(action, patientName);
    if (confirmed == true) {
      context.read<RendezVousBloc>().add(
        UpdateRendezVousStatus(
        rendezVousId: id,
        status: newStatus,
        patientId: patientId,
        doctorId: doctorId,
        patientName: patientName,
        doctorName: doctorName,
        recipientRole: 'patient',
        ),
      );
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'pending'.tr;
      case 'accepted':
        return 'accepted'.tr;
      case 'refused':
        return 'refused'.tr;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          title: Text("consultations".tr),
          backgroundColor: const Color(0xFF2FA7BB),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 30),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: BlocListener<RendezVousBloc, RendezVousState>(
          listener: (context, state) {
            if (state is RendezVousError) {
              showErrorSnackBar(context, state.message);
            } else if (state is RendezVousStatusUpdated) {
              showSuccessSnackBar(
                context,
                'consultation_updated_successfully'.tr,
              );
              if (doctorId != null) {
                context.read<RendezVousBloc>().add(
                  FetchRendezVous(doctorId: doctorId),
                );
              }
            }
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image responsive
                  Image.asset(
                    'assets/images/Consultation.png',
                    height: 250.h,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20.h),
                  // Liste des consultations
                  BlocBuilder<RendezVousBloc, RendezVousState>(
                    builder: (context, state) {
                      if (state is RendezVousLoading || doctorId == null) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is RendezVousLoaded) {
                        final pendingRendezVous =
                            state.rendezVous
                            .where((rv) => rv.status == 'pending')
                            .toList();
                        if (pendingRendezVous.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: ReusableTextWidget(
                                text: "no_pending_consultations".tr,
                                textSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingRendezVous.length,
                          itemBuilder: (context, index) {
                            final consultation = pendingRendezVous[index];
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ReusableTextWidget(
                                      text: "patient_label".tr.replaceAll(
                                        '{name}',
                                        consultation.patientName ??
                                            'unknown'.tr,
                                      ),
                                      textSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 8.h),
                                    ReusableTextWidget(
                                      text: "start_time_label".tr.replaceAll(
                                        '{time}',
                                        consultation.startTime
                                                ?.toLocal()
                                                .toString()
                                                .substring(0, 16) ??
                                            'not_defined'.tr,
                                      ),
                                      textSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                    SizedBox(height: 8.h),
                                    ReusableTextWidget(
                                      text: "status_label".tr.replaceAll(
                                        '{status}',
                                        _translateStatus(
                                          consultation.status ?? 'pending',
                                        ),
                                      ),
                                      textSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          consultation.status == 'pending'
                                          ? Colors.orange
                                              : consultation.status ==
                                                  'accepted'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    if (consultation.status == 'pending') ...[
                                      SizedBox(height: 16.h),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 12.h,
                                                ),
                                              ),
                                              onPressed: () async {
                                                final authLocalDataSource =
                                                    sl<AuthLocalDataSource>();
                                                final user =
                                                    await authLocalDataSource
                                                        .getUser();
                                                final doctorName =
                                                    '${user.name} ${user.lastName}'
                                                        .trim();
                                                _updateConsultationStatus(
                                                  consultation.id ?? '',
                                                  'accepted',
                                                  consultation.patientName ??
                                                      'unknown'.tr,
                                                  consultation.patientId ?? '',
                                                  consultation.doctorId ?? '',
                                                  doctorName,
                                                );
                                              },
                                              child: Text(
                                                'accept'.tr,
                                                style: GoogleFonts.raleway(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.whiteColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 12.h,
                                                ),
                                              ),
                                              onPressed: () async {
                                                final authLocalDataSource =
                                                    sl<AuthLocalDataSource>();
                                                final user =
                                                    await authLocalDataSource
                                                        .getUser();
                                                final doctorName =
                                                    '${user.name} ${user.lastName}'
                                                        .trim();
                                                _updateConsultationStatus(
                                                  consultation.id ?? '',
                                                  'refused',
                                                  consultation.patientName ??
                                                      'unknown'.tr,
                                                  consultation.patientId ?? '',
                                                  consultation.doctorId ?? '',
                                                  doctorName,
                                                );
                                              },
                                              child: Text(
                                                'refuse'.tr,
                                                style: GoogleFonts.raleway(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.whiteColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else if (state is RendezVousError) {
                        return ReusableTextWidget(
                          text: state.message,
                          textSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
