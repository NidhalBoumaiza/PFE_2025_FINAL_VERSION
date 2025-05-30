import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/reusable_text_field_widget.dart';
import '../../../../core/widgets/location_picker_widget.dart';
import '../../../../core/widgets/office_location_map_widget.dart';
import '../../domain/entities/medecin_entity.dart';
import '../../../../core/specialties.dart';
import '../widgets/profile_picture_widget.dart';
import 'password_screen.dart';

class SignupMedecinScreen extends StatefulWidget {
  final MedecinEntity medecinEntity;

  const SignupMedecinScreen({super.key, required this.medecinEntity});

  @override
  State<SignupMedecinScreen> createState() => _SignupMedecinScreenState();
}

class _SignupMedecinScreenState extends State<SignupMedecinScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController numLicenceController = TextEditingController();
  final TextEditingController consultationFeeController =
      TextEditingController();
  final TextEditingController appointmentDurationController =
      TextEditingController(text: "30");
  final TextEditingController educationController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  String? selectedSpecialty;
  File? _selectedProfilePicture;

  // Location fields
  LatLng? _selectedLocation;
  String _selectedAddress = '';

  @override
  void dispose() {
    numLicenceController.dispose();
    consultationFeeController.dispose();
    appointmentDurationController.dispose();
    educationController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  // Helper to parse education/experience input into List<Map<String, String>>
  List<Map<String, String>>? parseListInput(String? input) {
    if (input == null || input.isEmpty) return null;
    try {
      // Expect input like: "Degree:MD,Year:2010;Degree:PhD,Year:2015"
      final entries =
          input.split(';').where((e) => e.isNotEmpty).map((entry) {
            final parts = entry.split(',').map((e) => e.trim()).toList();
            final map = <String, String>{};
            for (var part in parts) {
              final keyValue = part.split(':');
              if (keyValue.length == 2) {
                map[keyValue[0]] = keyValue[1];
              }
            }
            return map;
          }).toList();
      return entries.isNotEmpty ? entries : null;
    } catch (e) {
      return null;
    }
  }

  void _openLocationPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationPickerWidget(
              initialLocation: _selectedLocation,
              title: 'select_office_location',
              onLocationSelected: (location, address) {
                setState(() {
                  _selectedLocation = location;
                  _selectedAddress = address;
                });
              },
            ),
      ),
    );
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
                  // Title
                  Center(
                    child: Text(
                      "professional_information".tr,
                      style: GoogleFonts.raleway(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Profile Picture Section
                  Center(
                    child: ProfilePictureWidget(
                      size: 120,
                      onImageSelected: (File? image) {
                        setState(() {
                          _selectedProfilePicture = image;
                        });
                      },
                      placeholderText: 'add_profile_picture'.tr,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Header image
                  Center(
                    child: Image.asset(
                      'assets/images/medecin.png',
                      height: 200.h,
                      width: 200.w,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Form fields
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Spécialité label
                        Text(
                          "specialty_label".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Spécialité dropdown
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
                          child: DropdownButtonFormField<String>(
                            value: selectedSpecialty,
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
                              hintText: "specialty_hint".tr,
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.medical_services_outlined,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                            ),
                            items:
                                getTranslatedSpecialties()
                                    .map(
                                      (specialty) => DropdownMenuItem(
                                        value: specialty,
                                        child: Text(
                                          specialty,
                                          style: GoogleFonts.raleway(
                                            fontSize: 15.sp,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSpecialty = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "specialty_required".tr;
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Office Location Section
                        Text(
                          "office_location_label".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Location selection card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedLocation != null) ...[
                                  // Show selected location map
                                  OfficeLocationMapWidget(
                                    latitude: _selectedLocation!.latitude,
                                    longitude: _selectedLocation!.longitude,
                                    address: _selectedAddress,
                                    height: 150,
                                    isInteractive: true,
                                    onTap: _openLocationPicker,
                                  ),
                                  SizedBox(height: 12.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: AppColors.primaryColor,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          _selectedAddress.isNotEmpty
                                              ? _selectedAddress
                                              : 'location_selected'.tr,
                                          style: GoogleFonts.raleway(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  // Show location selection button
                                  Container(
                                    width: double.infinity,
                                    height: 120.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_location_alt,
                                          size: 40.sp,
                                          color: AppColors.primaryColor,
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'tap_to_select_office_location'.tr,
                                          style: GoogleFonts.raleway(
                                            fontSize: 14.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                SizedBox(height: 12.h),

                                // Location selection button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _openLocationPicker,
                                    icon: Icon(
                                      _selectedLocation != null
                                          ? Icons.edit_location
                                          : Icons.location_searching,
                                      size: 20.sp,
                                    ),
                                    label: Text(
                                      _selectedLocation != null
                                          ? 'change_location'.tr
                                          : 'select_office_location'.tr,
                                      style: GoogleFonts.raleway(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryColor,
                                      side: BorderSide(
                                        color: AppColors.primaryColor,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Numéro de licence label
                        Text(
                          "license_number_label".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Numéro de licence field
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
                            controller: numLicenceController,
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
                              hintText: "license_number_hint".tr,
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "license_number_required".tr;
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Consultation Fee label
                        Text(
                          "consultation_fee_label".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Consultation Fee field
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
                            controller: consultationFeeController,
                            keyboardType: TextInputType.number,
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
                              hintText: "consultation_fee_hint".tr,
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "consultation_fee_required".tr;
                              }
                              if (double.tryParse(value) == null ||
                                  double.parse(value) <= 0) {
                                return "invalid_consultation_fee".tr;
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Appointment Duration label
                        Text(
                          "consultation_duration_label".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Appointment Duration field
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
                            controller: appointmentDurationController,
                            keyboardType: TextInputType.number,
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
                              hintText: "consultation_duration_hint".tr,
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.timer,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                              suffixText: "minutes".tr,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "consultation_duration_required".tr;
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return "invalid_consultation_duration".tr;
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Education label
                        Text(
                          "education_label".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Education field
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
                            controller: educationController,
                            style: GoogleFonts.raleway(
                              fontSize: 15.sp,
                              color: Colors.black87,
                            ),
                            maxLines: 3,
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
                              hintText:
                                  "education_hint"
                                      .tr, // e.g., "Degree:MD,Year:2010;Degree:PhD,Year:2015"
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.school_outlined,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Experience label
                        Text(
                          "experience_label".tr,
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Experience field
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
                            controller: experienceController,
                            style: GoogleFonts.raleway(
                              fontSize: 15.sp,
                              color: Colors.black87,
                            ),
                            maxLines: 3,
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
                              hintText:
                                  "experience_hint"
                                      .tr, // e.g., "Role:Surgeon,Years:5;Role:Consultant,Years:3"
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.work_outline,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Submit button
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
                          // Prepare location data
                          Map<String, dynamic>? locationData;
                          Map<String, String?>? addressData;

                          if (_selectedLocation != null) {
                            // Use GeoJSON format to match patient location format
                            locationData = {
                              'type': 'Point',
                              'coordinates': [
                                _selectedLocation!.longitude,
                                _selectedLocation!.latitude,
                              ],
                            };
                            addressData = {
                              'formatted_address':
                                  _selectedAddress.isNotEmpty
                                      ? _selectedAddress
                                      : null,
                              'coordinates':
                                  '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
                            };
                          }

                          final updatedMedecinEntity = MedecinEntity(
                            name: widget.medecinEntity.name,
                            lastName: widget.medecinEntity.lastName,
                            email: widget.medecinEntity.email,
                            role: widget.medecinEntity.role,
                            gender: widget.medecinEntity.gender,
                            phoneNumber: widget.medecinEntity.phoneNumber,
                            dateOfBirth: widget.medecinEntity.dateOfBirth,
                            speciality: selectedSpecialty!,
                            numLicence: numLicenceController.text,
                            appointmentDuration:
                                int.tryParse(
                                  appointmentDurationController.text,
                                ) ??
                                30,
                            consultationFee:
                                double.tryParse(
                                  consultationFeeController.text,
                                ) ??
                                0.0,
                            education: parseListInput(educationController.text),
                            experience: parseListInput(
                              experienceController.text,
                            ),
                            location: locationData,
                            address: addressData,
                          );
                          Get.to(
                            () => PasswordScreen(
                              entity: updatedMedecinEntity,
                              profilePicture: _selectedProfilePicture,
                            ),
                          );
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

                  // Back button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "cancel".tr,
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
