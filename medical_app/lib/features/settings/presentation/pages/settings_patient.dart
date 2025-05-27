import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/profile/presentation/pages/blocs/BLoC%20update%20profile/update_user_bloc.dart';
import 'package:medical_app/features/profile/presentation/pages/edit_patient_profile_page.dart';
import 'package:medical_app/widgets/theme_cubit_switch.dart';
import 'package:medical_app/i18n/app_translation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'change_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPatient extends StatefulWidget {
  const SettingsPatient({super.key});

  @override
  State<SettingsPatient> createState() => _SettingsPatientState();
}

class _SettingsPatientState extends State<SettingsPatient> {
  // Notification settings state
  bool _appointmentNotifications = true;
  bool _messageNotifications = true;
  bool _prescriptionNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  // Load notification settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appointmentNotifications =
          prefs.getBool('appointment_notifications') ?? true;
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _prescriptionNotifications =
          prefs.getBool('prescription_notifications') ?? true;
    });
  }

  // Save notification setting to SharedPreferences
  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "settings".tr,
          style: GoogleFonts.raleway(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 24, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("appearance".tr),
            const SizedBox(height: 8),
            const ThemeCubitSwitch(),

            const SizedBox(height: 24),
            _buildSectionTitle("language".tr),
            const SizedBox(height: 8),
            _buildLanguageSelection(),

            const SizedBox(height: 24),
            _buildSectionTitle("notifications".tr),
            const SizedBox(height: 8),
            _buildNotificationSettings(),

            const SizedBox(height: 24),
            _buildSectionTitle("account".tr),
            const SizedBox(height: 8),
            _buildAccountSettings(),

            const SizedBox(height: 24),
            _buildSectionTitle("about".tr),
            const SizedBox(height: 8),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.raleway(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildLanguageSelection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildLanguageOption('Français', 'fr'),
            const Divider(height: 1),
            _buildLanguageOption('English', 'en'),
            const Divider(height: 1),
            _buildLanguageOption('العربية', 'ar'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String langCode) {
    final isSelected = Get.locale?.languageCode == langCode;

    return InkWell(
      onTap: () async {
        Get.updateLocale(Locale(langCode));
        await LanguageService.saveLanguage(langCode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSwitchSetting(
              title: "appointments".tr,
              icon: Icons.calendar_today,
              value: _appointmentNotifications,
              settingKey: 'appointment_notifications',
            ),
            const Divider(height: 1),
            _buildSwitchSetting(
              title: "messages".tr,
              icon: Icons.message,
              value: _messageNotifications,
              settingKey: 'message_notifications',
            ),
            const Divider(height: 1),
            _buildSwitchSetting(
              title: "prescriptions".tr,
              icon: Icons.description,
              value: _prescriptionNotifications,
              settingKey: 'prescription_notifications',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required IconData icon,
    required bool value,
    String? settingKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.raleway(fontSize: 14)),
            ],
          ),
          Switch(
            value: value,
            onChanged: (val) async {
              if (settingKey != null) {
                await _saveNotificationSetting(settingKey, val);
                setState(() {
                  switch (settingKey) {
                    case 'appointment_notifications':
                      _appointmentNotifications = val;
                      break;
                    case 'message_notifications':
                      _messageNotifications = val;
                      break;
                    case 'prescription_notifications':
                      _prescriptionNotifications = val;
                      break;
                  }
                });

                // Show feedback to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? '$title ${"notifications".tr} ${"enabled".tr}'
                          : '$title ${"notifications".tr} ${"disabled".tr}',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              }
            },
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primaryColor),
            title: Text(
              "edit_profile".tr,
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            subtitle: Text(
              "update_your_personal_information".tr,
              style: GoogleFonts.raleway(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () async {
              try {
                final authLocalDataSource = di.sl<AuthLocalDataSource>();
                final userModel = await authLocalDataSource.getUser();

                // Convert UserModel to PatientEntity
                PatientEntity patientEntity = PatientEntity(
                  id: userModel.id,
                  name: userModel.name,
                  lastName: userModel.lastName,
                  email: userModel.email,
                  role: userModel.role,
                  gender: userModel.gender,
                  phoneNumber: userModel.phoneNumber,
                  dateOfBirth: userModel.dateOfBirth,
                  antecedent:
                      userModel is PatientModel
                          ? (userModel as PatientModel).antecedent
                          : '',
                  bloodType:
                      userModel is PatientModel
                          ? (userModel as PatientModel).bloodType
                          : null,
                  height:
                      userModel is PatientModel
                          ? (userModel as PatientModel).height
                          : null,
                  weight:
                      userModel is PatientModel
                          ? (userModel as PatientModel).weight
                          : null,
                  allergies:
                      userModel is PatientModel
                          ? (userModel as PatientModel).allergies
                          : null,
                  chronicDiseases:
                      userModel is PatientModel
                          ? (userModel as PatientModel).chronicDiseases
                          : null,
                  emergencyContact:
                      userModel is PatientModel
                          ? (userModel as PatientModel).emergencyContact
                          : null,
                );

                final updatedUser = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            EditPatientProfilePage(patient: patientEntity),
                  ),
                );

                if (updatedUser != null && updatedUser is PatientEntity) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('profile_updated_successfully'.tr),
                      backgroundColor: AppColors.primaryColor,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("failed_to_load_profile".tr),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.lock_outline,
              color: AppColors.primaryColor,
            ),
            title: Text(
              "change_password".tr,
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            subtitle: Text(
              "update_your_password".tr,
              style: GoogleFonts.raleway(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              "logout".tr,
              style: GoogleFonts.raleway(fontSize: 14, color: Colors.red),
            ),
            subtitle: Text(
              "sign_out_of_your_account".tr,
              style: GoogleFonts.raleway(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Medical App v1.0.0",
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "copyright".tr,
              style: GoogleFonts.raleway(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("logout".tr),
            content: Text("logout_confirmation".tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("cancel".tr),
              ),
              TextButton(
                onPressed: () {
                  // Logout logic
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("logout_success".tr)));
                  // Redirect to login screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text("logout".tr),
              ),
            ],
          ),
    );
  }
}
