import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/patient_entity.dart';
import 'medical_dossier_page.dart';

class PatientDetailsPage extends StatelessWidget {
  final PatientEntity patient;

  const PatientDetailsPage({Key? key, required this.patient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(
      '🏥 PatientDetailsPage: Building details for patient ${patient.fullName}',
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
                  _buildPatientOverview(context, isDarkMode),
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
                colors: [Colors.green[400]!, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.person, size: 32.sp, color: Colors.white),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
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
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'Patient Profile',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Patient Profile',
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
        _buildActionButton(
          icon: Icons.edit,
          label: 'Modifier',
          color: Colors.blue,
          onPressed: () {},
          isDarkMode: isDarkMode,
        ),
        SizedBox(width: 12.w),

        // Print button
        SizedBox(width: 12.w),
        // Medical Dossier button
        ElevatedButton.icon(
          onPressed: () => _viewMedicalDossier(context),
          icon: Icon(Icons.folder_shared, size: 18.sp, color: Colors.white),
          label: Text(
            'Dossier médical',
            style: TextStyle(fontSize: 14.sp, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.sp, color: color),
      label: Text(label, style: TextStyle(fontSize: 14.sp, color: color)),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  Widget _buildPatientOverview(BuildContext context, bool isDarkMode) {
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
              patient.email,
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
              patient.phoneNumber ?? 'Not provided',
              Icons.phone,
              Colors.green,
              isDarkMode,
            ),
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: _buildOverviewItem(
              context,
              'Age',
              '${patient.age ?? 'N/A'} years',
              Icons.cake,
              Colors.orange,
              isDarkMode,
            ),
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: _buildOverviewItem(
              context,
              'Status',
              patient.accountStatus ? 'Active' : 'Inactive',
              Icons.circle,
              patient.accountStatus ? Colors.green : Colors.red,
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
              _buildMedicalInfoCard(context, isDarkMode),
            ],
          ),
        ),
        SizedBox(width: 24.w),
        // Right Column - Secondary Information
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildEmergencyContactCard(context, isDarkMode),
              SizedBox(height: 24.h),
              _buildAccountInfoCard(context, isDarkMode),
              SizedBox(height: 24.h),
              _buildRecentActivityCard(context, isDarkMode),
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
                    patient.fullName,
                    isDarkMode,
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    context,
                    'Gender',
                    patient.gender ?? 'Not specified',
                    isDarkMode,
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    context,
                    'Blood Type',
                    patient.bloodType ?? 'Unknown',
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
                    patient.dateOfBirth != null
                        ? '${patient.dateOfBirth!.day}/${patient.dateOfBirth!.month}/${patient.dateOfBirth!.year}'
                        : 'Not provided',
                    isDarkMode,
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    context,
                    'Height',
                    patient.height != null
                        ? '${patient.height!.toStringAsFixed(1)} cm'
                        : 'Not recorded',
                    isDarkMode,
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    context,
                    'Weight',
                    patient.weight != null
                        ? '${patient.weight!.toStringAsFixed(1)} kg'
                        : 'Not recorded',
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
            patient.address ?? 'Not provided',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard(BuildContext context, bool isDarkMode) {
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
            'Medical Information',
            Icons.medical_information,
            Colors.red,
            isDarkMode,
          ),
          SizedBox(height: 20.h),
          _buildMedicalSection(
            context,
            'Medical History',
            patient.antecedent,
            isDarkMode,
          ),
          SizedBox(height: 16.h),
          _buildMedicalSection(
            context,
            'Allergies',
            patient.allergies?.isNotEmpty == true
                ? patient.allergies!.join(', ')
                : 'No known allergies',
            isDarkMode,
          ),
          SizedBox(height: 16.h),
          _buildMedicalSection(
            context,
            'Chronic Diseases',
            patient.chronicDiseases?.isNotEmpty == true
                ? patient.chronicDiseases!.join(', ')
                : 'No chronic diseases recorded',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context, bool isDarkMode) {
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
            'Emergency Contact',
            Icons.emergency,
            Colors.orange,
            isDarkMode,
          ),
          SizedBox(height: 20.h),
          _buildInfoItem(
            context,
            'Name',
            patient.emergencyContactName ?? 'Not provided',
            isDarkMode,
          ),
          SizedBox(height: 16.h),
          _buildInfoItem(
            context,
            'Phone',
            patient.emergencyContactPhone ?? 'Not provided',
            isDarkMode,
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
            Colors.indigo,
            isDarkMode,
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color:
                  patient.accountStatus ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              patient.accountStatus ? 'Active Account' : 'Inactive Account',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color:
                    patient.accountStatus ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoItem(
            context,
            'Last Login',
            patient.lastLogin != null
                ? '${patient.lastLogin!.day}/${patient.lastLogin!.month}/${patient.lastLogin!.year}'
                : 'Never',
            isDarkMode,
          ),
          SizedBox(height: 16.h),
          _buildInfoItem(
            context,
            'Account Created',
            patient.createdAt != null
                ? '${patient.createdAt!.day}/${patient.createdAt!.month}/${patient.createdAt!.year}'
                : 'Not available',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context, bool isDarkMode) {
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
            'Recent Activity',
            Icons.history,
            Colors.purple,
            isDarkMode,
          ),
          SizedBox(height: 20.h),
          Text(
            'No recent activity to display',
            style: TextStyle(
              fontSize: 14.sp,
              color:
                  isDarkMode
                      ? theme.colorScheme.onSurface.withOpacity(0.7)
                      : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
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

  Widget _buildMedicalSection(
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

  Future<void> _printPatientDetails(BuildContext context) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 2, color: PdfColors.blue),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Patient Details Report',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Generated on ${DateTime.now().toString().split(' ')[0]}',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          'Patient Profile',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Patient Name and Status
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      patient.fullName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color:
                            patient.accountStatus
                                ? PdfColors.green100
                                : PdfColors.red100,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        patient.accountStatus ? 'Active' : 'Inactive',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color:
                              patient.accountStatus
                                  ? PdfColors.green800
                                  : PdfColors.red800,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Personal Information Section
                _buildPdfSection('Personal Information', [
                  _buildPdfRow('Full Name', patient.fullName),
                  _buildPdfRow('Email', patient.email),
                  _buildPdfRow(
                    'Phone Number',
                    patient.phoneNumber ?? 'Not provided',
                  ),
                  _buildPdfRow('Gender', patient.gender ?? 'Not specified'),
                  _buildPdfRow(
                    'Date of Birth',
                    patient.dateOfBirth != null
                        ? '${patient.dateOfBirth!.day}/${patient.dateOfBirth!.month}/${patient.dateOfBirth!.year}'
                        : 'Not provided',
                  ),
                  _buildPdfRow('Age', '${patient.age ?? 'N/A'} years'),
                  _buildPdfRow('Address', patient.address ?? 'Not provided'),
                ]),
                pw.SizedBox(height: 20),

                // Medical Information Section
                _buildPdfSection('Medical Information', [
                  _buildPdfRow('Blood Type', patient.bloodType ?? 'Unknown'),
                  _buildPdfRow(
                    'Height',
                    patient.height != null
                        ? '${patient.height!.toStringAsFixed(1)} cm'
                        : 'Not recorded',
                  ),
                  _buildPdfRow(
                    'Weight',
                    patient.weight != null
                        ? '${patient.weight!.toStringAsFixed(1)} kg'
                        : 'Not recorded',
                  ),
                  _buildPdfTextArea(
                    'Medical History',
                    patient.antecedent ?? 'Not provided',
                  ),
                  _buildPdfTextArea(
                    'Allergies',
                    patient.allergies?.isNotEmpty == true
                        ? patient.allergies!.join(', ')
                        : 'No known allergies',
                  ),
                  _buildPdfTextArea(
                    'Chronic Diseases',
                    patient.chronicDiseases?.isNotEmpty == true
                        ? patient.chronicDiseases!.join(', ')
                        : 'No chronic diseases recorded',
                  ),
                ]),
                pw.SizedBox(height: 20),

                // Emergency Contact Section
                _buildPdfSection('Emergency Contact', [
                  _buildPdfRow(
                    'Name',
                    patient.emergencyContactName ?? 'Not provided',
                  ),
                  _buildPdfRow(
                    'Phone',
                    patient.emergencyContactPhone ?? 'Not provided',
                  ),
                ]),
                pw.SizedBox(height: 20),

                // Account Information Section
                _buildPdfSection('Account Information', [
                  _buildPdfRow(
                    'Account Status',
                    patient.accountStatus ? 'Active' : 'Inactive',
                  ),
                  _buildPdfRow(
                    'Last Login',
                    patient.lastLogin != null
                        ? '${patient.lastLogin!.day}/${patient.lastLogin!.month}/${patient.lastLogin!.year}'
                        : 'Never',
                  ),
                  _buildPdfRow(
                    'Account Created',
                    patient.createdAt != null
                        ? '${patient.createdAt!.day}/${patient.createdAt!.month}/${patient.createdAt!.year}'
                        : 'Not available',
                  ),
                ]),

                pw.Spacer(),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(width: 1, color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Medical Admin Dashboard - Confidential Patient Information',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Patient_${patient.fullName.replaceAll(' ', '_')}_Details.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTextArea(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewMedicalDossier(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicalDossierPage(patient: patient),
      ),
    );
  }
}
