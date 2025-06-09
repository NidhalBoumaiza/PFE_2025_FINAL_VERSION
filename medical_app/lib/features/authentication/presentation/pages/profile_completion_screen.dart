import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/profile/presentation/pages/blocs/BLoC%20update%20profile/update_user_bloc.dart';
import 'package:medical_app/features/home/presentation/pages/home_patient.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final UserEntity user;

  const ProfileCompletionScreen({super.key, required this.user});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController antecedentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? selectedDateOfBirth;
  String selectedGender = 'Homme';
  String? selectedBloodType;

  final List<String> genderOptions = ['Homme', 'Femme'];
  final List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    phoneController.text = widget.user.phoneNumber ?? '';
    selectedGender = widget.user.gender ?? 'Homme';
    selectedDateOfBirth = widget.user.dateOfBirth;
  }

  @override
  void dispose() {
    phoneController.dispose();
    heightController.dispose();
    weightController.dispose();
    antecedentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          elevation: 0,
          title: Text(
            "complete_profile".tr.isNotEmpty
                ? "complete_profile".tr
                : "Complete Your Profile",
            style: GoogleFonts.raleway(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          size: 40.sp,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "welcome_google_user".tr.isNotEmpty
                              ? "welcome_google_user".tr
                              : "Welcome, ${widget.user.name}!",
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "complete_profile_message".tr.isNotEmpty
                              ? "complete_profile_message".tr
                              : "Please complete your medical profile to get personalized care",
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Phone number
                  _buildSectionTitle(
                    "phone_number_label".tr.isNotEmpty
                        ? "phone_number_label".tr
                        : "Phone Number",
                  ),
                  SizedBox(height: 8.h),
                  _buildTextField(
                    controller: phoneController,
                    hintText:
                        "phone_number_hint".tr.isNotEmpty
                            ? "phone_number_hint".tr
                            : "Enter phone number",
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "phone_number_required".tr.isNotEmpty
                            ? "phone_number_required".tr
                            : "Phone number is required";
                      }
                      if (value.length < 8) {
                        return "phone_min_length".tr.isNotEmpty
                            ? "phone_min_length".tr
                            : "Invalid phone number";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20.h),

                  // Date of birth
                  _buildSectionTitle(
                    "date_of_birth_label".tr.isNotEmpty
                        ? "date_of_birth_label".tr
                        : "Date of Birth",
                  ),
                  SizedBox(height: 8.h),
                  _buildDatePickerField(),

                  SizedBox(height: 20.h),

                  // Gender
                  _buildSectionTitle(
                    "gender".tr.isNotEmpty ? "gender".tr : "Gender",
                  ),
                  SizedBox(height: 8.h),
                  _buildGenderDropdown(),

                  SizedBox(height: 20.h),

                  // Height and Weight row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              "height_cm".tr.isNotEmpty
                                  ? "height_cm".tr
                                  : "Height (cm)",
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              controller: heightController,
                              hintText: "170",
                              prefixIcon: Icons.height_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              "weight_kg".tr.isNotEmpty
                                  ? "weight_kg".tr
                                  : "Weight (kg)",
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              controller: weightController,
                              hintText: "70",
                              prefixIcon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Blood type
                  _buildSectionTitle(
                    "blood_type".tr.isNotEmpty
                        ? "blood_type".tr
                        : "Blood Type (Optional)",
                  ),
                  SizedBox(height: 8.h),
                  _buildBloodTypeDropdown(),

                  SizedBox(height: 20.h),

                  // Medical history
                  _buildSectionTitle(
                    "medical_history".tr.isNotEmpty
                        ? "medical_history".tr
                        : "Medical History (Optional)",
                  ),
                  SizedBox(height: 8.h),
                  _buildTextField(
                    controller: antecedentController,
                    hintText:
                        "antecedent_placeholder".tr.isNotEmpty
                            ? "antecedent_placeholder".tr
                            : "Any medical conditions, surgeries, etc.",
                    prefixIcon: Icons.medical_information_outlined,
                    maxLines: 3,
                  ),

                  SizedBox(height: 30.h),

                  // Complete profile button
                  BlocConsumer<UpdateUserBloc, UpdateUserState>(
                    listener: (context, state) {
                      if (state is UpdateUserSuccess) {
                        showSuccessSnackBar(
                          context,
                          "profile_completed_success".tr.isNotEmpty
                              ? "profile_completed_success".tr
                              : "Profile completed successfully!",
                        );
                        navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                          context,
                          const HomePatient(),
                        );
                      } else if (state is UpdateUserFailure) {
                        showErrorSnackBar(context, state.message);
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is UpdateUserLoading;
                      return Container(
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
                          onPressed: isLoading ? null : _completeProfile,
                          child:
                              isLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  )
                                  : Text(
                                    "complete_profile_button".tr.isNotEmpty
                                        ? "complete_profile_button".tr
                                        : "Complete Profile",
                                    style: GoogleFonts.raleway(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // Skip for now button
                  Container(
                    width: double.infinity,
                    height: 55.h,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(color: AppColors.primaryColor),
                        ),
                      ),
                      onPressed: () {
                        navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                          context,
                          const HomePatient(),
                        );
                      },
                      child: Text(
                        "skip_for_now".tr.isNotEmpty
                            ? "skip_for_now".tr
                            : "Skip for Now",
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.raleway(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
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
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.raleway(fontSize: 15.sp, color: Colors.black87),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.raleway(
            color: Colors.grey[400],
            fontSize: 15.sp,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.primaryColor,
            size: 22.sp,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
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
        readOnly: true,
        style: GoogleFonts.raleway(fontSize: 15.sp, color: Colors.black87),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
          ),
          hintText:
              selectedDateOfBirth != null
                  ? "${selectedDateOfBirth!.day}/${selectedDateOfBirth!.month}/${selectedDateOfBirth!.year}"
                  : "date_of_birth_hint".tr.isNotEmpty
                  ? "date_of_birth_hint".tr
                  : "Select date of birth",
          hintStyle: GoogleFonts.raleway(
            color:
                selectedDateOfBirth != null ? Colors.black87 : Colors.grey[400],
            fontSize: 15.sp,
          ),
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: AppColors.primaryColor,
            size: 22.sp,
          ),
        ),
        onTap: _selectDateOfBirth,
        validator: (value) {
          if (selectedDateOfBirth == null) {
            return "date_of_birth_required".tr.isNotEmpty
                ? "date_of_birth_required".tr
                : "Date of birth is required";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
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
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
          ),
          prefixIcon: Icon(
            Icons.person_outline,
            color: AppColors.primaryColor,
            size: 22.sp,
          ),
        ),
        items:
            genderOptions.map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(
                  gender,
                  style: GoogleFonts.raleway(
                    fontSize: 15.sp,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedGender = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
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
      child: DropdownButtonFormField<String>(
        value: selectedBloodType,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
          ),
          hintText:
              "blood_type_placeholder".tr.isNotEmpty
                  ? "blood_type_placeholder".tr
                  : "Select blood type",
          hintStyle: GoogleFonts.raleway(
            color: Colors.grey[400],
            fontSize: 15.sp,
          ),
          prefixIcon: Icon(
            Icons.bloodtype_outlined,
            color: AppColors.primaryColor,
            size: 22.sp,
          ),
        ),
        items:
            bloodTypes.map((String bloodType) {
              return DropdownMenuItem<String>(
                value: bloodType,
                child: Text(
                  bloodType,
                  style: GoogleFonts.raleway(
                    fontSize: 15.sp,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedBloodType = newValue;
          });
        },
      ),
    );
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDateOfBirth) {
      setState(() {
        selectedDateOfBirth = picked;
      });
    }
  }

  void _completeProfile() {
    print('🔄 Profile completion button pressed');

    // Debug: Check each field value before validation
    print('📋 Form field values:');
    print('  - Phone: "${phoneController.text}"');
    print('  - Date of birth: $selectedDateOfBirth');
    print('  - Gender: "$selectedGender"');
    print('  - Height: "${heightController.text}"');
    print('  - Weight: "${weightController.text}"');
    print('  - Blood type: $selectedBloodType');
    print('  - Medical history: "${antecedentController.text}"');

    if (_formKey.currentState!.validate()) {
      print('✅ Form validation passed');

      // Create updated patient model with completed information
      final updatedPatient = PatientModel(
        id: widget.user.id,
        name: widget.user.name,
        lastName: widget.user.lastName,
        email: widget.user.email,
        role: widget.user.role,
        gender: selectedGender,
        phoneNumber: phoneController.text.trim(),
        dateOfBirth: selectedDateOfBirth,
        antecedent:
            antecedentController.text.trim().isEmpty
                ? '' // Provide empty string if not filled
                : antecedentController.text.trim(),
        bloodType: selectedBloodType,
        height:
            heightController.text.isNotEmpty
                ? double.tryParse(heightController.text)
                : null,
        weight:
            weightController.text.isNotEmpty
                ? double.tryParse(weightController.text)
                : null,
        allergies: [],
        chronicDiseases: [],
        emergencyContact: null,
        address: widget.user.address,
        location: widget.user.location,
        accountStatus: widget.user.accountStatus ?? true,
        verificationCode: widget.user.verificationCode,
        validationCodeExpiresAt: widget.user.validationCodeExpiresAt,
        fcmToken: widget.user.fcmToken,
        profilePictureUrl: widget.user.profilePictureUrl,
      );

      print('👤 Created patient model: ${updatedPatient.toJson()}');

      // Use the update user bloc to save the changes
      print('📤 Dispatching UpdateUserEvent to bloc');
      context.read<UpdateUserBloc>().add(UpdateUserEvent(updatedPatient));
    } else {
      print('❌ Form validation failed');
      print('🔍 Checking validation errors...');

      // Check each validator manually to see which ones fail
      final phoneError =
          phoneController.text.isEmpty || phoneController.text.length < 8;
      final dateError = selectedDateOfBirth == null;

      print(
        '  - Phone validation error: $phoneError (value: "${phoneController.text}")',
      );
      print(
        '  - Date validation error: $dateError (value: $selectedDateOfBirth)',
      );
    }
  }
}
