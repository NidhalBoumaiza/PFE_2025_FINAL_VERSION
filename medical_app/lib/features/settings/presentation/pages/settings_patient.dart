import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/profile/presentation/pages/blocs/BLoC%20update%20profile/update_user_bloc.dart';
import 'package:medical_app/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:medical_app/widgets/theme_cubit_switch.dart';
import 'package:medical_app/i18n/app_translation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'change_password_screen.dart';

class SettingsPatient extends StatefulWidget {
  const SettingsPatient({super.key});

  @override
  State<SettingsPatient> createState() => _SettingsPatientState();
}

class _SettingsPatientState extends State<SettingsPatient> {
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
              value: true,
            ),
            const Divider(height: 1),
            _buildSwitchSetting(
              title: "medications".tr,
              icon: Icons.medication,
              value: true,
            ),
            const Divider(height: 1),
            _buildSwitchSetting(
              title: "messages".tr,
              icon: Icons.message,
              value: true,
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
            onChanged: (val) {
              // Implement notification settings logic
              setState(() {});
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
            leading: const Icon(Icons.person, color: AppColors.primaryColor),
            title: Text(
              "edit_profile".tr,
              style: GoogleFonts.raleway(fontSize: 14),
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
                );

                final updatedUser = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditProfileScreen(user: patientEntity),
                  ),
                );

                if (updatedUser != null && updatedUser is UserEntity) {
                  // Dispatch update event to the BLoC
                  context.read<UpdateUserBloc>().add(
                    UpdateUserEvent(updatedUser),
                  );

                  // Cache updated user if successful
                  if (userModel is PatientModel) {
                    await authLocalDataSource.cacheUser(
                      (userModel as PatientModel).copyWith(
                        name: updatedUser.name,
                        lastName: updatedUser.lastName,
                        phoneNumber: updatedUser.phoneNumber,
                        gender: updatedUser.gender,
                        dateOfBirth: updatedUser.dateOfBirth,
                        antecedent:
                            updatedUser is PatientEntity
                                ? (updatedUser as PatientEntity).antecedent
                                : '',
                      ),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to load profile: $e")),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primaryColor),
            title: Text(
              "change_password".tr,
              style: GoogleFonts.raleway(fontSize: 14),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              // Logique de déconnexion
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("logout_success".tr)));
              // Rediriger vers la page de connexion
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
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
}
