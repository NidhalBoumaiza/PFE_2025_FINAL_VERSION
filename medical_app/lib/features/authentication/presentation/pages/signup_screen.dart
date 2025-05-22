import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/cubit/toggle%20cubit/toggle_cubit.dart';
import 'package:medical_app/features/authentication/presentation/pages/signup_medecin_screen.dart';
import 'package:medical_app/features/authentication/presentation/pages/signup_patient_screen.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/medecin_entity.dart';
import '../../domain/entities/patient_entity.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController numTel = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  String gender = 'Homme';
  DateTime? selectedDate;

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    numTel.dispose();
    birthdayController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // Calculate the minimum birth date (16 years ago from today)
    final DateTime today = DateTime.now();
    final DateTime minimumBirthDate = DateTime(
      today.year - 16,
      today.month,
      today.day,
    );

    // The date picker enforces age restriction by:
    // 1. Setting lastDate to minimumBirthDate (16 years ago) - user can't select more recent dates
    // 2. Using initialDate of 25 years ago as a reasonable default
    // This ensures users must be at least 16 years old without needing additional validation
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            selectedDate ?? DateTime(today.year - 25, today.month, today.day),
        firstDate: DateTime(1900),
        lastDate: minimumBirthDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          selectedDate = picked;
          birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
        });
      }
    } catch (e) {
      print('Error selecting date: $e');
      // Show friendly error message to user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("error".tr)));
    }
  }

  // This function is still needed as a safety check
  bool isUserAtLeast16() {
    if (selectedDate == null) return false;

    final DateTime today = DateTime.now();
    final DateTime minimumBirthDate = DateTime(
      today.year - 16,
      today.month,
      today.day,
    );

    return selectedDate!.isBefore(minimumBirthDate) ||
        selectedDate!.isAtSameMomentAs(minimumBirthDate);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and back button
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.primaryColor,
                            size: 20.sp,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "signup_title".tr,
                              style: GoogleFonts.raleway(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 40.w), // Balance the header
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Improved user type toggle
                  BlocBuilder<ToggleCubit, ToggleState>(
                    builder: (context, state) {
                      final isPatient = state is PatientState;
                      return Container(
                        height: 56.h,
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        child: Row(
                          children: [
                            // Patient toggle
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!isPatient) {
                                    context.read<ToggleCubit>().toggle();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color:
                                        isPatient
                                            ? AppColors.primaryColor
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(28.r),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color:
                                              isPatient
                                                  ? Colors.white
                                                  : Colors.grey.shade600,
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          "patient".tr,
                                          style: GoogleFonts.raleway(
                                            color:
                                                isPatient
                                                    ? Colors.white
                                                    : Colors.grey.shade600,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Doctor toggle
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (isPatient) {
                                    context.read<ToggleCubit>().toggle();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color:
                                        !isPatient
                                            ? AppColors.primaryColor
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(28.r),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medical_services_outlined,
                                          color:
                                              !isPatient
                                                  ? Colors.white
                                                  : Colors.grey.shade600,
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          "doctors".tr,
                                          style: GoogleFonts.raleway(
                                            color:
                                                !isPatient
                                                    ? Colors.white
                                                    : Colors.grey.shade600,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 30.h),

                  // Form fields
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom field
                        _buildInputField(
                          controller: nomController,
                          label: "name_label".tr,
                          hint: "name_hint".tr,
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "name_required".tr;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20.h),

                        // Prénom field
                        _buildInputField(
                          controller: prenomController,
                          label: "first_name_label".tr,
                          hint: "first_name_hint".tr,
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "first_name_required".tr;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20.h),

                        // Email field
                        _buildInputField(
                          controller: emailController,
                          label: "email".tr,
                          hint: "email_hint".tr,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "email_required".tr;
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return "invalid_email_message".tr;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20.h),

                        // Téléphone field
                        _buildInputField(
                          controller: numTel,
                          label: "phone_number_label".tr,
                          hint: "phone_number_hint".tr,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "phone_number_required".tr;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20.h),

                        // Date de naissance field with calendar picker
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "date_of_birth_label".tr,
                              style: GoogleFonts.raleway(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                            SizedBox(height: 10.h),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: birthdayController,
                                readOnly: true,
                                onTap: () => _selectDate(context),
                                style: GoogleFonts.raleway(
                                  fontSize: 15.sp,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 16.h,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      width: 1,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  hintText: "date_of_birth_hint".tr,
                                  hintStyle: GoogleFonts.raleway(
                                    color: Colors.grey[400],
                                    fontSize: 15.sp,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppColors.primaryColor,
                                    size: 22.sp,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.primaryColor,
                                    size: 22.sp,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "date_of_birth_required".tr;
                                  }
                                  // Extra validation as a safety check
                                  if (!isUserAtLeast16()) {
                                    return "You must be at least 16 years old"
                                        .tr;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        // Genre selection with improved UI
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "gender".tr,
                              style: GoogleFonts.raleway(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                            SizedBox(height: 10.h),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Male option
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          gender = "Homme";
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              gender == "Homme"
                                                  ? AppColors.primaryColor
                                                      .withOpacity(0.1)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.male,
                                              color:
                                                  gender == "Homme"
                                                      ? AppColors.primaryColor
                                                      : Colors.grey,
                                              size: 22.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              "Male".tr,
                                              style: GoogleFonts.raleway(
                                                fontSize: 15.sp,
                                                fontWeight:
                                                    gender == "Homme"
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                color:
                                                    gender == "Homme"
                                                        ? AppColors.primaryColor
                                                        : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Female option
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          gender = "Femme";
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              gender == "Femme"
                                                  ? AppColors.primaryColor
                                                      .withOpacity(0.1)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.female,
                                              color:
                                                  gender == "Femme"
                                                      ? AppColors.primaryColor
                                                      : Colors.grey,
                                              size: 22.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              "Female".tr,
                                              style: GoogleFonts.raleway(
                                                fontSize: 15.sp,
                                                fontWeight:
                                                    gender == "Femme"
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                color:
                                                    gender == "Femme"
                                                        ? AppColors.primaryColor
                                                        : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Submit button with improved UI
                  Container(
                    width: double.infinity,
                    height: 55.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Date is already validated in the form and enforced by date picker
                          // No need for additional checks here

                          if (context.read<ToggleCubit>().state
                              is PatientState) {
                            final patientEntity = PatientEntity(
                              name: nomController.text,
                              lastName: prenomController.text,
                              email: emailController.text,
                              role: 'patient',
                              gender: gender,
                              phoneNumber: numTel.text,
                              dateOfBirth: selectedDate!,
                              antecedent: '',
                            );
                            Get.to(
                              () => SignupPatientScreen(
                                patientEntity: patientEntity,
                              ),
                            );
                          } else {
                            final medecinEntity = MedecinEntity(
                              name: nomController.text,
                              lastName: prenomController.text,
                              email: emailController.text,
                              role: 'medecin',
                              gender: gender,
                              phoneNumber: numTel.text,
                              dateOfBirth: selectedDate!,
                              speciality: '',
                              numLicence: '',
                            );
                            Get.to(
                              () => SignupMedecinScreen(
                                medecinEntity: medecinEntity,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        "next_button".tr,
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Back to login
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "sign_in".tr,
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
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

  // Helper method to build input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 10.h),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.raleway(fontSize: 15.sp, color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              hintText: hint,
              hintStyle: GoogleFonts.raleway(
                color: Colors.grey[400],
                fontSize: 15.sp,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 22.sp,
              ),
            ),
            keyboardType: keyboardType,
            validator: validator,
          ),
        ),
      ],
    );
  }
}
