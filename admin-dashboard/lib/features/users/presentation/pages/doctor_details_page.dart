import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/doctor_entity.dart';

class DoctorDetailsPage extends StatelessWidget {
  final DoctorEntity doctor;

  const DoctorDetailsPage({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(
      '👨‍⚕️ DoctorDetailsPage: Building details for doctor ${doctor.fullName}',
    );

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? theme.colorScheme.background : Colors.grey[50],
      body: Column(
        children: [
          _buildWebHeader(context, isDarkMode),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDoctorOverview(context, isDarkMode),
                  SizedBox(height: 24.h),
                  _buildWebDashboardGrid(context, isDarkMode),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color:
                  isDarkMode ? theme.colorScheme.onSurface : Colors.grey[700],
              size: 24.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: 16.w),
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.medical_services,
              size: 32.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.fullName,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode
                            ? theme.colorScheme.onSurface
                            : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        doctor.speciality ?? 'Doctor',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Doctor Profile',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color:
                            isDarkMode
                                ? theme.colorScheme.onSurface.withOpacity(0.7)
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildQuickActions(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Only show a view profile indicator, remove all action buttons
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.visibility,
                size: 18.sp,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                'Consultation du profil',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorOverview(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewItem(
              context,
              'Email',
              doctor.email,
              Icons.email,
              Colors.blue,
              isDarkMode,
            ),
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: _buildOverviewItem(
              context,
              'Phone',
              doctor.phoneNumber ?? 'Not provided',
              Icons.phone,
              Colors.green,
              isDarkMode,
            ),
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: _buildOverviewItem(
              context,
              'Experience',
              doctor.experienceYears ?? 'Not specified',
              Icons.work,
              Colors.orange,
              isDarkMode,
            ),
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: _buildOverviewItem(
              context,
              'Status',
              doctor.accountStatus ? 'Active' : 'Inactive',
              Icons.circle,
              doctor.accountStatus ? Colors.green : Colors.red,
              isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 18.sp, color: color),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color:
                    isDarkMode
                        ? theme.colorScheme.onSurface.withOpacity(0.7)
                        : Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? theme.colorScheme.onSurface : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildWebDashboardGrid(BuildContext context, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Main Information
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildPersonalInfoCard(context, isDarkMode),
              SizedBox(height: 24.h),
              _buildProfessionalInfoCard(context, isDarkMode),
            ],
          ),
        ),
        SizedBox(width: 24.w),
        // Right Column - Secondary Information
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildAccountInfoCard(context, isDarkMode),
              SizedBox(height: 24.h),
              _buildPracticeInfoCard(context, isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            context,
            'Personal Information',
            Icons.person,
            Colors.blue,
            isDarkMode,
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn([
                  _buildInfoItem(
                    context,
                    'Full Name',
                    doctor.fullName,
                    isDarkMode,
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    context,
                    'Gender',
                    doctor.gender ?? 'Not specified',
                    isDarkMode,
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    context,
                    'Age',
                    '${doctor.calculatedAge ?? 'N/A'} years',
                    isDarkMode,
                  ),
                ]),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: _buildInfoColumn([
                  _buildInfoItem(
                    context,
                    'Date of Birth',
                    doctor.dateOfBirth != null
                        ? '${doctor.dateOfBirth!.day}/${doctor.dateOfBirth!.month}/${doctor.dateOfBirth!.year}'
                        : 'Not provided',
                    isDarkMode,
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    context,
                    'License Number',
                    doctor.numLicence ?? 'Not provided',
                    isDarkMode,
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    context,
                    'Phone',
                    doctor.phoneNumber ?? 'Not provided',
                    isDarkMode,
                  ),
                ]),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildInfoItem(
            context,
            'Address',
            doctor.address ?? 'Not provided',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoCard(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            context,
            'Professional Information',
            Icons.local_hospital,
            Colors.indigo,
            isDarkMode,
          ),
          SizedBox(height: 20.h),
          if (doctor.speciality != null) ...[
            _buildSpecialtyHighlight(context, isDarkMode),
            SizedBox(height: 16.h),
          ],
          _buildProfessionalSection(
            context,
            'Education Summary',
            doctor.educationSummary,
            isDarkMode,
          ),
          SizedBox(height: 16.h),
          _buildProfessionalSection(
            context,
            'Professional Experience',
            doctor.experienceYears,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyHighlight(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[50]!, Colors.indigo[100]!],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[400]!, Colors.indigo[600]!],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Speciality',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo[700],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  doctor.speciality!,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeInfoCard(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            context,
            'Practice Information',
            Icons.schedule,
            Colors.green,
            isDarkMode,
          ),
          SizedBox(height: 20.h),
          _buildPracticeItem(
            context,
            'Appointment Duration',
            '${doctor.appointmentDuration} minutes',
            Icons.schedule,
            Colors.blue,
            isDarkMode,
          ),
          SizedBox(height: 16.h),
          _buildPracticeItem(
            context,
            'Consultation Fee',
            doctor.consultationFee != null
                ? '${doctor.consultationFee!.toStringAsFixed(2)} DT'
                : 'Not set',
            Icons.monetization_on,
            Colors.green,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color:
                        isDarkMode
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            context,
            'Account Information',
            Icons.account_circle,
            Colors.orange,
            isDarkMode,
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: doctor.accountStatus ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              doctor.accountStatus ? 'Active Account' : 'Inactive Account',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color:
                    doctor.accountStatus ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoItem(
            context,
            'Account Created',
            doctor.createdAt != null
                ? '${doctor.createdAt!.day}/${doctor.createdAt!.month}/${doctor.createdAt!.year}'
                : 'Not available',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.sp, color: color),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? theme.colorScheme.onSurface : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color:
                isDarkMode
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? theme.colorScheme.onSurface : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalSection(
    BuildContext context,
    String title,
    String? content,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? theme.colorScheme.onSurface : Colors.grey[800],
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? theme.colorScheme.background.withOpacity(0.5)
                    : Colors.grey[50],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color:
                  isDarkMode
                      ? theme.colorScheme.outline.withOpacity(0.3)
                      : Colors.grey[200]!,
            ),
          ),
          child: Text(
            content ?? 'Not provided',
            style: TextStyle(
              fontSize: 14.sp,
              color:
                  isDarkMode
                      ? theme.colorScheme.onSurface.withOpacity(0.8)
                      : Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
