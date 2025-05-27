import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../authentication/presentation/pages/login_screen.dart';
import 'blocs/BLoC update profile/update_user_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/features/settings/presentation/pages/SettingsPage.dart';

class ProfilMedecin extends StatefulWidget {
  const ProfilMedecin({Key? key}) : super(key: key);

  @override
  State<ProfilMedecin> createState() => _ProfilMedecinState();
}

class _ProfilMedecinState extends State<ProfilMedecin> {
  MedecinEntity? _medecin;

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

      // Handle education with proper type casting
      List<Map<String, String>>? education;
      if (userMap['education'] is List) {
        education =
            (userMap['education'] as List).where((item) => item is Map).map((
              item,
            ) {
              return Map<String, String>.from(
                (item as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              );
            }).toList();
      }

      // Handle experience with proper type casting
      List<Map<String, String>>? experience;
      if (userMap['experience'] is List) {
        experience =
            (userMap['experience'] as List).where((item) => item is Map).map((
              item,
            ) {
              return Map<String, String>.from(
                (item as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              );
            }).toList();
      }

      // Handle consultation fee
      double? consultationFee;
      if (userMap['consultationFee'] != null) {
        consultationFee =
            userMap['consultationFee'] is double
                ? userMap['consultationFee'] as double
                : userMap['consultationFee'] is int
                ? (userMap['consultationFee'] as int).toDouble()
                : null;
      }

      // Handle address and location
      Map<String, String?>? address;
      if (userMap['address'] is Map) {
        address = Map<String, String?>.from(
          (userMap['address'] as Map).map(
            (key, value) => MapEntry(key.toString(), value?.toString()),
          ),
        );
      }

      Map<String, dynamic>? location;
      if (userMap['location'] is Map) {
        location = Map<String, dynamic>.from(userMap['location'] as Map);
      }

      setState(() {
        _medecin = MedecinEntity.create(
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
          speciality: userMap['speciality'] as String?,
          numLicence: userMap['numLicence'] as String?,
          accountStatus: userMap['accountStatus'] as bool?,
          verificationCode: userMap['verificationCode'] as int?,
          validationCodeExpiresAt:
              userMap['validationCodeExpiresAt'] != null
                  ? DateTime.parse(userMap['validationCodeExpiresAt'] as String)
                  : null,
          appointmentDuration: userMap['appointmentDuration'] as int? ?? 30,
          consultationFee: consultationFee,
          education: education,
          experience: experience,
          address: address,
          location: location,
        );
      });
    }
  }

  // Translate specialty based on the value from the database
  String _translateSpecialty(String? specialty) {
    if (specialty == null || specialty.isEmpty) {
      return 'not_specified'.tr;
    }

    // Convert specialty to lowercase for case-insensitive matching
    final specialtyLower = specialty.toLowerCase();

    // Map of common specialties to their translation keys
    final Map<String, String> specialtyTranslationKeys = {
      'cardiology': 'cardiologist',
      'cardiologie': 'cardiologist',
      'dermatology': 'dermatologist',
      'dermatologie': 'dermatologist',
      'neurology': 'neurologist',
      'neurologie': 'neurologist',
      'pediatrics': 'pediatrician',
      'pédiatrie': 'pediatrician',
      'orthopedics': 'orthopedic',
      'orthopédie': 'orthopedic',
      'general': 'general_practitioner',
      'généraliste': 'general_practitioner',
      'psychology': 'psychologist',
      'psychologie': 'psychologist',
      'gynecology': 'gynecologist',
      'gynécologie': 'gynecologist',
      'ophthalmology': 'ophthalmologist',
      'ophtalmologie': 'ophthalmologist',
      'dentistry': 'dentist',
      'dentisterie': 'dentist',
      'pulmonology': 'pulmonologist',
      'pneumologie': 'pulmonologist',
      'nutrition': 'nutritionist',
      'esthétique': 'aesthetic_doctor',
      'aesthetic': 'aesthetic_doctor',
    };

    // Try to find a matching key in our map
    for (final entry in specialtyTranslationKeys.entries) {
      if (specialtyLower.contains(entry.key)) {
        return entry.value.tr;
      }
    }

    // If no match is found, return the original specialty
    return specialty;
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('logout'.tr, style: GoogleFonts.raleway(fontSize: 22.sp)),
        content: Text(
          'confirm_logout'.tr,
          style: GoogleFonts.raleway(fontSize: 18.sp),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'cancel'.tr,
              style: GoogleFonts.raleway(fontSize: 16.sp),
            ),
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
                      "logout_success".tr,
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
                  'logout_error'.tr.replaceAll('{0}', e.toString()),
                );
              }
            },
            child: Text(
              'logout'.tr,
              style: GoogleFonts.raleway(fontSize: 16.sp, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() {
    Get.snackbar('info'.tr, 'change_profile_picture_message'.tr);
  }

  void _showAppointmentDurationDialog() {
    int selectedDuration = _medecin?.appointmentDuration ?? 30;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'consultation_duration_label'.tr,
                style: GoogleFonts.raleway(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'choose_consultation_duration'.tr,
                    style: GoogleFonts.raleway(fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'duration_label'.tr + ': ',
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DropdownButton<int>(
                        value: selectedDuration,
                        items:
                            [15, 20, 30, 45, 60, 90, 120].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                  '$value ' + 'minutes'.tr,
                                  style: GoogleFonts.raleway(fontSize: 16.sp),
                                ),
                              );
                            }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDuration = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'cancel'.tr,
                    style: GoogleFonts.raleway(
                      color: Colors.grey,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      if (_medecin?.id != null) {
                        // Update Firestore
                        final FirebaseFirestore firestore =
                            FirebaseFirestore.instance;
                        await firestore
                            .collection('medecins')
                            .doc(_medecin!.id)
                            .update({'appointmentDuration': selectedDuration});

                        // Update local state
                        setState(() {
                          _medecin = MedecinEntity(
                            id: _medecin!.id,
                            name: _medecin!.name,
                            lastName: _medecin!.lastName,
                            email: _medecin!.email,
                            role: _medecin!.role,
                            gender: _medecin!.gender,
                            phoneNumber: _medecin!.phoneNumber,
                            dateOfBirth: _medecin!.dateOfBirth,
                            speciality: _medecin!.speciality,
                            numLicence: _medecin!.numLicence,
                            appointmentDuration: selectedDuration,
                            consultationFee: _medecin!.consultationFee,
                            education: _medecin!.education,
                            experience: _medecin!.experience,
                            address: _medecin!.address,
                            location: _medecin!.location,
                          );
                        });

                        // Show success message
                        showSuccessSnackBar(
                          context,
                          'consultation_duration_updated'.tr,
                        );
                      }
                    } catch (e) {
                      // Show error message
                      showErrorSnackBar(context, 'update_error'.tr + ': $e');
                    }
                    // Close dialog
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'confirm'.tr,
                    style: GoogleFonts.raleway(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocConsumer<UpdateUserBloc, UpdateUserState>(
          listener: (context, state) {
            if (state is UpdateUserSuccess) {
              setState(() {
                _medecin = state.user as MedecinEntity;
              });
              showSuccessSnackBar(context, 'profile_saved_successfully'.tr);
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
            return _medecin == null
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
                : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: 24.h,
                    bottom: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
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
                                    color: AppColors.whiteColor,
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
                                  child: Container(
                                    width: 32.w,
                                    height: 32.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2fa7bb),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: AppColors.whiteColor,
                                        size: 18.sp,
                                      ),
                                      onPressed: _changeProfilePicture,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Dr. ${_medecin!.name} ${_medecin!.lastName}',
                              style: GoogleFonts.raleway(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _translateSpecialty(_medecin!.speciality),
                              style: GoogleFonts.raleway(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _medecin!.email,
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        'personal_information'.tr,
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildInfoTile(
                        'phone_number_label'.tr,
                        _medecin!.phoneNumber,
                      ),
                      _buildInfoTile('gender'.tr, _medecin!.gender),
                      _buildInfoTile(
                        'date_of_birth_label'.tr,
                        _medecin!.dateOfBirth
                                ?.toIso8601String()
                                .split('T')
                                .first ??
                            'not_specified'.tr,
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        'professional_information'.tr,
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildInfoTile(
                        'specialty_label'.tr,
                        _translateSpecialty(_medecin!.speciality),
                      ),
                      _buildInfoTile(
                        'license_number_label'.tr,
                        _medecin!.numLicence ?? 'not_specified'.tr,
                      ),
                      _buildInfoTile(
                        'consultation_duration_label'.tr,
                        '${_medecin!.appointmentDuration} ' + 'minutes'.tr,
                      ),
                      if (_medecin?.consultationFee != null)
                        _buildInfoTile(
                          'consultation_fee_label'.tr,
                          '${_medecin!.consultationFee} ' + 'currency'.tr,
                        ),
                      if (_medecin?.address != null &&
                          _medecin!.address!.isNotEmpty)
                        _buildInfoTile(
                          'address'.tr,
                          _medecin!.address!.values
                              .where(
                                (value) => value != null && value.isNotEmpty,
                              )
                              .join(', '),
                        ),
                      SizedBox(height: 20.h),
                      if (_medecin?.education != null &&
                          _medecin!.education!.isNotEmpty) ...[
                        Text(
                          'education'.tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ..._medecin!.education!
                            .map(
                              (edu) => Card(
                                margin: EdgeInsets.only(bottom: 10.h),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 12.h,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (edu['institution'] != null)
                                        Text(
                                          edu['institution']!,
                                          style: GoogleFonts.raleway(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      if (edu['degree'] != null)
                                        Text(
                                          edu['degree']!,
                                          style: GoogleFonts.raleway(
                                            fontSize: 14.sp,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      if (edu['year'] != null)
                                        Text(
                                          edu['year']!,
                                          style: GoogleFonts.raleway(
                                            fontSize: 12.sp,
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      if (_medecin?.experience != null &&
                          _medecin!.experience!.isNotEmpty) ...[
                        SizedBox(height: 20.h),
                        Text(
                          'experience'.tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ..._medecin!.experience!
                            .map(
                              (exp) => Card(
                                margin: EdgeInsets.only(bottom: 10.h),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 12.h,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (exp['position'] != null)
                                        Text(
                                          exp['position']!,
                                          style: GoogleFonts.raleway(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      if (exp['organization'] != null)
                                        Text(
                                          exp['organization']!,
                                          style: GoogleFonts.raleway(
                                            fontSize: 14.sp,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      if (exp['period'] != null)
                                        Text(
                                          exp['period']!,
                                          style: GoogleFonts.raleway(
                                            fontSize: 12.sp,
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      SizedBox(height: 8.h),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: _showAppointmentDurationDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'modify_consultation_duration'.tr,
                                  style: GoogleFonts.raleway(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                Icon(
                                  Icons.edit,
                                  color: AppColors.primaryColor,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
