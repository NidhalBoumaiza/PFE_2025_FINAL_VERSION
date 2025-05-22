import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/status_appointment.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';


class AppointmentDetailsPage extends StatefulWidget {
  final String id;

  const AppointmentDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  void _loadAppointmentDetails() {
    // Use FetchRendezVous event with an ID filter
    context.read<RendezVousBloc>().add(FetchRendezVous(appointmentId: widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'appointment_details'.tr,
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<RendezVousBloc, RendezVousState>(
        builder: (context, state) {
          if (state is RendezVousLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          } else if (state is RendezVousLoaded) {
            // Find appointment by ID
            final appointment = state.rendezVous.firstWhere(
              (a) => a.id == widget.id, 
              orElse: () => RendezVousEntity(
                startTime: DateTime.now(), 
                status: 'not_found'
              )
            );
            
            if (appointment.status == 'not_found') {
              return Center(
                child: Text(
                  'appointment_not_found'.tr,
                  style: GoogleFonts.raleway(fontSize: 16.sp),
                ),
              );
            }
            
            return _buildAppointmentDetailsView(appointment);
          } else if (state is RendezVousError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: GoogleFonts.raleway(color: Colors.red),
              ),
            );
          }
          return Center(
            child: Text(
              'appointment_not_found'.tr,
              style: GoogleFonts.raleway(fontSize: 16.sp),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentDetailsView(RendezVousEntity appointment) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(appointment),
          SizedBox(height: 16.h),
          _buildStatusCard(appointment),
          SizedBox(height: 16.h),
          _buildActionButtons(appointment),
        ],
      ),
    );
  }

  Widget _buildInfoCard(RendezVousEntity appointment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appointment_info'.tr,
              style: GoogleFonts.raleway(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            Divider(height: 24.h, thickness: 1),
            _buildInfoRow('patient'.tr, appointment.patientName ?? 'Unknown'),
            _buildInfoRow('doctor'.tr, appointment.doctorName ?? 'Unknown'),
            _buildInfoRow('date'.tr, appointment.startTime.toString().substring(0, 10)),
            _buildInfoRow('time'.tr, _formatTime(appointment.startTime)),
            _buildInfoRow('specialty'.tr, appointment.speciality ?? 'General'),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusCard(RendezVousEntity appointment) {
    Color statusColor;
    String statusText;

    switch (appointment.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'pending'.tr;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'accepted'.tr;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'rejected'.tr;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'completed'.tr;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'unknown'.tr;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Text(
              'status'.tr,
              style: GoogleFonts.raleway(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.raleway(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(RendezVousEntity appointment) {
    // Only show accept/reject buttons if the appointment is pending
    if (appointment.status.toLowerCase() == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.read<RendezVousBloc>().add(
                  UpdateRendezVousStatus(
                    rendezVousId: appointment.id!,
                    status: 'accepted',
                    patientId: appointment.patientId ?? '',
                    doctorId: appointment.doctorId ?? '',
                    patientName: appointment.patientName ?? '',
                    doctorName: appointment.doctorName ?? '',
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'accept'.tr,
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.read<RendezVousBloc>().add(
                  UpdateRendezVousStatus(
                    rendezVousId: appointment.id!,
                    status: 'rejected',
                    patientId: appointment.patientId ?? '',
                    doctorId: appointment.doctorId ?? '',
                    patientName: appointment.patientName ?? '',
                    doctorName: appointment.doctorName ?? '',
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'reject'.tr,
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 