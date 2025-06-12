import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/user_model.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/authentication/presentation/blocs/delete_account_bloc/delete_account_bloc.dart';
import 'package:medical_app/features/authentication/presentation/blocs/delete_account_bloc/delete_account_event.dart';
import 'package:medical_app/features/authentication/presentation/blocs/delete_account_bloc/delete_account_state.dart';
import 'package:medical_app/features/profile/presentation/pages/ProfilMedecin.dart';
import 'package:medical_app/features/profile/presentation/pages/edit_patient_profile_page.dart';
import 'package:medical_app/widgets/theme_cubit_switch.dart';
import 'package:medical_app/i18n/app_translation.dart';
import 'package:medical_app/features/authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:medical_app/features/settings/presentation/pages/change_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
          "Paramètres",
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
            _buildSectionTitle("Apparence"),
            const SizedBox(height: 8),
            const ThemeCubitSwitch(),

            const SizedBox(height: 24),
            _buildSectionTitle("Notifications"),
            const SizedBox(height: 8),
            _buildNotificationSettings(),

            const SizedBox(height: 24),
            _buildSectionTitle("Compte"),
            const SizedBox(height: 8),
            _buildAccountSettings(),

            const SizedBox(height: 24),
            _buildSectionTitle("À propos"),
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

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.notifications,
              color: AppColors.primaryColor,
            ),
            title: Text(
              "Paramètres de notification",
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            subtitle: Text(
              "Gérer vos préférences de notification",
              style: GoogleFonts.raleway(
                fontSize: 12,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text("Paramètres de notification"),
                      content: Text("Paramètres de notification bientôt disponibles"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        ),
                      ],
                    ),
              );
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSwitchSetting(
                  title: "Rendez-vous",
                  icon: Icons.calendar_today,
                  value: _appointmentNotifications,
                  settingKey: 'appointment_notifications',
                ),
                const Divider(height: 1),
                _buildSwitchSetting(
                  title: "Messages",
                  icon: Icons.message,
                  value: _messageNotifications,
                  settingKey: 'message_notifications',
                ),
                const Divider(height: 1),
                _buildSwitchSetting(
                  title: "Ordonnances",
                  icon: Icons.description,
                  value: _prescriptionNotifications,
                  settingKey: 'prescription_notifications',
                ),
              ],
            ),
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
          // Edit Profile option for all users
          FutureBuilder<UserEntity?>(
            future: _getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final user = snapshot.data!;
                final isDoctor = user.role == 'medecin';

                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.edit,
                        color: AppColors.primaryColor,
                      ),
                      title: Text(
                        "Modifier le profil",
                        style: GoogleFonts.raleway(fontSize: 14),
                      ),
                      subtitle: Text(
                        isDoctor
                            ? "Modifier le profil et la localisation du cabinet"
                            : "Mettre à jour vos informations personnelles",
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[600],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onTap: () async {
                        if (isDoctor && user is MedecinEntity) {
                          // Use specialized doctor profile editor with location features
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilMedecin(),
                            ),
                          );
                          if (result != null) {
                            // Handle updated doctor profile if needed
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Profil mis à jour avec succès',
                                ),
                                backgroundColor: AppColors.primaryColor,
                              ),
                            );
                          }
                        } else if (user is PatientEntity) {
                          // Use specialized patient profile editor
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      EditPatientProfilePage(patient: user),
                            ),
                          );
                          if (result != null) {
                            // Handle updated patient profile if needed
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Profil mis à jour avec succès',
                                ),
                                backgroundColor: AppColors.primaryColor,
                              ),
                            );
                          }
                        } else {
                          // This shouldn't happen as we handle both doctors and patients above
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de la mise à jour du profil'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.lock_outline,
              color: AppColors.primaryColor,
            ),
            title: Text(
              "Changer le mot de passe",
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            subtitle: Text(
              "Mettre à jour votre mot de passe",
              style: GoogleFonts.raleway(
                fontSize: 12,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[600],
              ),
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
              "Déconnexion",
              style: GoogleFonts.raleway(fontSize: 14, color: Colors.red),
            ),
            subtitle: Text(
              "Se déconnecter de votre compte",
              style: GoogleFonts.raleway(
                fontSize: 12,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[600],
              ),
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              "Supprimer le compte",
              style: GoogleFonts.raleway(fontSize: 14, color: Colors.red),
            ),
            subtitle: Text(
              "Cette action supprimera définitivement votre compte et toutes vos données",
              style: GoogleFonts.raleway(
                fontSize: 12,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
        ],
      ),
    );
  }

  Future<UserEntity?> _getCurrentUser() async {
    try {
      final authLocalDataSource = di.sl<AuthLocalDataSource>();
      final userModel = await authLocalDataSource.getUser();

      // Convert UserModel to appropriate entity
      if (userModel is MedecinModel) {
        return MedecinEntity(
          id: userModel.id,
          name: userModel.name,
          lastName: userModel.lastName,
          email: userModel.email,
          role: userModel.role,
          gender: userModel.gender,
          phoneNumber: userModel.phoneNumber,
          dateOfBirth: userModel.dateOfBirth,
          speciality: userModel.speciality,
          numLicence: userModel.numLicence,
          appointmentDuration: userModel.appointmentDuration,
          consultationFee: userModel.consultationFee,
          education: userModel.education,
          experience: userModel.experience,
          location: userModel.location,
          address: userModel.address,
          accountStatus: userModel.accountStatus,
          verificationCode: userModel.verificationCode,
          validationCodeExpiresAt: userModel.validationCodeExpiresAt,
          fcmToken: userModel.fcmToken,
        );
      } else if (userModel is PatientModel) {
        return PatientEntity(
          id: userModel.id,
          name: userModel.name,
          lastName: userModel.lastName,
          email: userModel.email,
          role: userModel.role,
          gender: userModel.gender,
          phoneNumber: userModel.phoneNumber,
          dateOfBirth: userModel.dateOfBirth,
          antecedent: userModel.antecedent,
          bloodType: userModel.bloodType,
          height: userModel.height,
          weight: userModel.weight,
          allergies: userModel.allergies,
          chronicDiseases: userModel.chronicDiseases,
          emergencyContact: userModel.emergencyContact,
        );
      } else {
        return UserEntity(
          id: userModel.id,
          name: userModel.name,
          lastName: userModel.lastName,
          email: userModel.email,
          role: userModel.role,
          gender: userModel.gender,
          phoneNumber: userModel.phoneNumber,
          dateOfBirth: userModel.dateOfBirth,
        );
      }
    } catch (e) {
      return null;
    }
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
                          ? '$title Notifications activées'
                          : '$title Notifications désactivées',
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
              "MediLink v1.0.0",
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "© 2025 Medical App. Tous droits réservés.",
              style: GoogleFonts.raleway(
                fontSize: 12,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
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
            title: Text("Déconnexion"),
            content: Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Annuler"),
              ),
              TextButton(
                onPressed: () {
                  // Logout logic
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Déconnexion réussie")));
                  // Redirect to login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text("Déconnexion"),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => BlocProvider(
            create: (context) => di.sl<DeleteAccountBloc>(),
            child: BlocConsumer<DeleteAccountBloc, DeleteAccountState>(
              listener: (context, state) {
                if (state is DeleteAccountSuccess) {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Compte supprimé avec succès"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Navigate to login screen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                } else if (state is DeleteAccountError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return AlertDialog(
                  title: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        "Supprimer le compte",
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cette action supprimera définitivement votre compte et toutes vos données.",
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Confirmez votre mot de passe pour supprimer",
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Entrez votre mot de passe",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Entrez votre mot de passe";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          state is DeleteAccountLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                      child: Text("Annuler"),
                    ),
                    ElevatedButton(
                      onPressed:
                          state is DeleteAccountLoading
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  // Show confirmation dialog
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text(
                                            "Confirmer la suppression du compte",
                                          ),
                                          content: Text(
                                            "Attention : cette action supprimera définitivement votre compte et toutes vos données.",
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black87,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                              child: Text("Annuler"),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: Text("Supprimer"),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirmed == true) {
                                    // Get current user ID
                                    try {
                                      final authLocalDataSource =
                                          di.sl<AuthLocalDataSource>();
                                      final userModel =
                                          await authLocalDataSource.getUser();

                                      if (userModel.id != null) {
                                        context.read<DeleteAccountBloc>().add(
                                          DeleteAccountRequested(
                                            userId: userModel.id!,
                                            password: passwordController.text,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Erreur lors de la suppression du compte",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          state is DeleteAccountLoading
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text("Supprimer"),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }
}
