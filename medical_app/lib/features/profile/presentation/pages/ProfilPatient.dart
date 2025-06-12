import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/core/util/snackbar_message.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../authentication/presentation/pages/login_screen.dart';
import 'blocs/BLoC update profile/update_user_bloc.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_bloc.dart';
import 'package:medical_app/features/dossier_medical/presentation/pages/dossier_medical_screen.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:medical_app/features/settings/presentation/pages/settings_patient.dart';

class ProfilePatient extends StatefulWidget {
  const ProfilePatient({Key? key}) : super(key: key);

  @override
  State<ProfilePatient> createState() => _ProfilePatientState();
}

class _ProfilePatientState extends State<ProfilePatient> {
  PatientEntity? _patient;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('CACHED_USER');
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;

      // Handle allergies with proper type casting
      List<String>? allergies;
      if (userMap['allergies'] != null) {
        allergies =
            (userMap['allergies'] as List)
                .map((item) => item.toString())
                .toList();
      }

      // Handle chronicDiseases with proper type casting
      List<String>? chronicDiseases;
      if (userMap['chronicDiseases'] != null) {
        chronicDiseases =
            (userMap['chronicDiseases'] as List)
                .map((item) => item.toString())
                .toList();
      }

      // Handle emergency contact
      Map<String, String?>? emergencyContact;
      if (userMap['emergencyContact'] is Map) {
        emergencyContact = Map<String, String?>.from(
          (userMap['emergencyContact'] as Map).map(
            (key, value) => MapEntry(key.toString(), value?.toString()),
          ),
        );
      }

      // Handle height and weight
      double? height;
      if (userMap['height'] != null) {
        height =
            userMap['height'] is double
                ? userMap['height'] as double
                : userMap['height'] is int
                ? (userMap['height'] as int).toDouble()
                : null;
      }

      double? weight;
      if (userMap['weight'] != null) {
        weight =
            userMap['weight'] is double
                ? userMap['weight'] as double
                : userMap['weight'] is int
                ? (userMap['weight'] as int).toDouble()
                : null;
      }

      setState(() {
        _patient = PatientEntity(
          id: userMap['id'] as String?,
          name: userMap['name'] as String,
          lastName: userMap['lastName'] as String,
          email: userMap['email'] as String,
          role: userMap['role'] as String,
          gender: userMap['gender'] as String,
          phoneNumber: userMap['phoneNumber'] as String,
          dateOfBirth:
              userMap['dateOfBirth'] != null
                  ? DateTime.parse(userMap['dateOfBirth'] as String)
                  : null,
          antecedent: userMap['antecedent'] as String,
          bloodType: userMap['bloodType'] as String?,
          height: height,
          weight: weight,
          allergies: allergies,
          chronicDiseases: chronicDiseases,
          emergencyContact: emergencyContact,
          address: userMap['address'] as Map<String, String?>?,
          location: userMap['location'] as Map<String, dynamic>?,
        );
      });
    }
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Déconnexion', style: GoogleFonts.raleway(fontSize: 22.sp)),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: GoogleFonts.raleway(fontSize: 18.sp),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('Annuler', style: GoogleFonts.raleway(fontSize: 16.sp)),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('CACHED_USER');
                await prefs.remove('TOKEN');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Déconnexion réussie",
                      style: GoogleFonts.raleway(fontSize: 16.sp),
                    ),
                  ),
                );

                navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                  context,
                  const LoginScreen(),
                );
              } catch (e) {
                showErrorSnackBar(
                  context,
                  'Erreur lors de la déconnexion : ${e.toString()}',
                );
              }
            },
            child: Text(
              'Déconnexion',
              style: GoogleFonts.raleway(fontSize: 16.sp, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() {
    Get.snackbar(
      'Info',
      'Fonctionnalité de changement de photo de profil à venir',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocConsumer<UpdateUserBloc, UpdateUserState>(
          listener: (context, state) {
            if (state is UpdateUserSuccess) {
              setState(() {
                _patient = state.user as PatientEntity;
              });
              showSuccessSnackBar(context, 'Profil sauvegardé avec succès');
            } else if (state is UpdateUserFailure) {
              showErrorSnackBar(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is UpdateUserLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }
            return _patient == null
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppColors.primaryColor.withOpacity(0.15)
                                  : AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color:
                                        isDarkMode
                                            ? Colors.grey[800]
                                            : AppColors.whiteColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50.r,
                                    backgroundColor: AppColors.primaryColor
                                        .withOpacity(0.2),
                                    child: Icon(
                                      Icons.person,
                                      size: 60.sp,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _changeProfilePicture,
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '${_patient!.name} ${_patient!.lastName}',
                              style: GoogleFonts.raleway(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _patient!.email,
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color:
                                    isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Informations personnelles',
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildInfoTile(
                        'Numéro de téléphone',
                        _patient!.phoneNumber,
                      ),
                      _buildInfoTile('Sexe', _patient!.gender),
                      _buildInfoTile(
                        'Date de naissance',
                        _patient!.dateOfBirth
                                ?.toIso8601String()
                                .split('T')
                                .first ??
                            'Non spécifié',
                      ),
                      _buildInfoTile(
                        'Antécédent',
                        _patient!.antecedent ?? 'Non spécifié',
                      ),
                      if (_patient?.bloodType != null)
                        _buildInfoTile('Groupe sanguin', _patient!.bloodType!),
                      if (_patient?.height != null)
                        _buildInfoTile('Taille', "${_patient!.height} cm"),
                      if (_patient?.weight != null)
                        _buildInfoTile('Poids', "${_patient!.weight} kg"),
                      if (_patient?.allergies != null &&
                          _patient!.allergies!.isNotEmpty)
                        _buildInfoTile(
                          'Allergies',
                          _patient!.allergies!.join(", "),
                        ),
                      if (_patient?.chronicDiseases != null &&
                          _patient!.chronicDiseases!.isNotEmpty)
                        _buildInfoTile(
                          'Maladies chroniques',
                          _patient!.chronicDiseases!.join(", "),
                        ),
                      if (_patient?.address != null &&
                          _patient!.address!.isNotEmpty)
                        _buildInfoTile(
                          'Adresse',
                          _patient!.address!.values
                              .where(
                                (value) => value != null && value.isNotEmpty,
                              )
                              .join(', '),
                        ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Contact d\'urgence',
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      if (_patient?.emergencyContact != null &&
                          _patient!.emergencyContact!.containsKey('name') &&
                          _patient!.emergencyContact!['name'] != null)
                        _buildInfoTile(
                          'Nom du contact d\'urgence',
                          _patient!.emergencyContact!['name']!,
                        ),
                      if (_patient?.emergencyContact != null &&
                          _patient!.emergencyContact!.containsKey(
                            'relationship',
                          ) &&
                          _patient!.emergencyContact!['relationship'] != null)
                        _buildInfoTile(
                          'Relation',
                          _patient!.emergencyContact!['relationship']!,
                        ),
                      if (_patient?.emergencyContact != null &&
                          _patient!.emergencyContact!.containsKey(
                            'phoneNumber',
                          ) &&
                          _patient!.emergencyContact!['phoneNumber'] != null)
                        _buildInfoTile(
                          'Téléphone d\'urgence',
                          _patient!.emergencyContact!['phoneNumber']!,
                        ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Paramètres',
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      InkWell(
                        onTap: () {
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                            context,
                            const SettingsPatient(),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.settings,
                              color: AppColors.primaryColor,
                            ),
                            title: Text(
                              'Paramètres de l\'application',
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.primaryColor,
                              size: 16.sp,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Dossier médical',
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      InkWell(
                        onTap: () {
                          if (_patient?.id != null) {
                            navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                              context,
                              BlocProvider<DossierMedicalBloc>(
                                create:
                                    (context) => di.sl<DossierMedicalBloc>(),
                                child: DossierMedicalScreen(
                                  patientId: _patient!.id!,
                                ),
                              ),
                            );
                          } else {
                            SnackBarMessage().showErrorSnackBar(
                              message: 'Erreur d\'accès au dossier médical',
                              context: context,
                            );
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.folder_shared_outlined,
                              color: AppColors.primaryColor,
                              size: 20.sp,
                            ),
                            title: Text(
                              'Gérer le dossier médical',
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.primaryColor,
                              size: 16.sp,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: Icon(Icons.logout, size: 18.sp),
                            label: Text(
                              'Déconnexion',
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        trailing: Text(
          value,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }
}
