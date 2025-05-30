import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/location_picker_widget.dart';
import '../../../../core/widgets/office_location_map_widget.dart';
import '../../../authentication/domain/entities/medecin_entity.dart';

class EditDoctorProfilePage extends StatefulWidget {
  final MedecinEntity doctor;

  const EditDoctorProfilePage({Key? key, required this.doctor})
    : super(key: key);

  @override
  State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _appointmentDurationController;

  // Location fields
  LatLng? _selectedLocation;
  String _selectedAddress = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCurrentLocation();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.doctor.name);
    _lastNameController = TextEditingController(text: widget.doctor.lastName);
    _phoneController = TextEditingController(text: widget.doctor.phoneNumber);
    _consultationFeeController = TextEditingController(
      text: widget.doctor.consultationFee?.toString() ?? '',
    );
    _appointmentDurationController = TextEditingController(
      text: widget.doctor.appointmentDuration.toString(),
    );
  }

  void _loadCurrentLocation() {
    if (widget.doctor.location != null) {
      double? lat;
      double? lng;
      
      // Handle both old format (separate lat/lng fields) and new GeoJSON format
      if (widget.doctor.location!.containsKey('coordinates') && 
          widget.doctor.location!['coordinates'] is List) {
        // New GeoJSON format: [longitude, latitude]
        final coordinates = widget.doctor.location!['coordinates'] as List;
        if (coordinates.length >= 2) {
          lng = (coordinates[0] as num?)?.toDouble();
          lat = (coordinates[1] as num?)?.toDouble();
        }
      } else {
        // Old format: separate latitude and longitude fields
        lat = widget.doctor.location!['latitude']?.toDouble();
        lng = widget.doctor.location!['longitude']?.toDouble();
      }

      if (lat != null && lng != null) {
        _selectedLocation = LatLng(lat, lng);
      }
    }

    if (widget.doctor.address != null) {
      _selectedAddress =
          widget.doctor.address!['formatted_address'] ??
          widget.doctor.address!['coordinates'] ??
          '';
    }
  }

  void _openLocationPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationPickerWidget(
              initialLocation: _selectedLocation,
              title: 'edit_office_location'.tr,
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
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
              _selectedAddress.isNotEmpty ? _selectedAddress : null,
          'coordinates':
              '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
        };
      }

      // Create updated doctor entity
      final updatedDoctor = MedecinEntity(
        id: widget.doctor.id,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: widget.doctor.email,
        role: widget.doctor.role,
        gender: widget.doctor.gender,
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: widget.doctor.dateOfBirth,
        speciality: widget.doctor.speciality,
        numLicence: widget.doctor.numLicence,
        appointmentDuration:
            int.tryParse(_appointmentDurationController.text) ?? 30,
        consultationFee: double.tryParse(_consultationFeeController.text),
        education: widget.doctor.education,
        experience: widget.doctor.experience,
        location: locationData,
        address: addressData,
        accountStatus: widget.doctor.accountStatus,
        verificationCode: widget.doctor.verificationCode,
        validationCodeExpiresAt: widget.doctor.validationCodeExpiresAt,
        fcmToken: widget.doctor.fcmToken,
      );

      // Here you would typically call a BLoC or repository to save the updated profile
      // For now, we'll just show a success message

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'profile_updated_successfully'.tr,
            style: GoogleFonts.raleway(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.of(context).pop(updatedDoctor);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'error_updating_profile'.tr,
            style: GoogleFonts.raleway(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'edit_profile'.tr,
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'save'.tr,
                style: GoogleFonts.raleway(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 100.h,
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 50.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Dr. ${widget.doctor.name} ${widget.doctor.lastName}',
                      style: GoogleFonts.raleway(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    Text(
                      widget.doctor.speciality ?? 'specialty_not_specified'.tr,
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Personal Information Section
              _buildSectionTitle('personal_information'.tr),
              SizedBox(height: 16.h),

              _buildTextField(
                controller: _nameController,
                label: 'first_name_label'.tr,
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'first_name_required'.tr;
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.h),

              _buildTextField(
                controller: _lastNameController,
                label: 'name_label'.tr,
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'name_required'.tr;
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.h),

              _buildTextField(
                controller: _phoneController,
                label: 'phone_number_label'.tr,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'phone_number_required'.tr;
                  }
                  return null;
                },
              ),

              SizedBox(height: 24.h),

              // Professional Information Section
              _buildSectionTitle('professional_information'.tr),
              SizedBox(height: 16.h),

              _buildTextField(
                controller: _consultationFeeController,
                label: 'consultation_fee'.tr,
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'invalid_consultation_fee'.tr;
                    }
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.h),

              _buildTextField(
                controller: _appointmentDurationController,
                label: 'appointment_duration'.tr,
                icon: Icons.schedule,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'appointment_duration_required'.tr;
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'invalid_appointment_duration'.tr;
                  }
                  return null;
                },
              ),

              SizedBox(height: 24.h),

              // Office Location Section
              _buildSectionTitle('office_location'.tr),
              SizedBox(height: 16.h),

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
                        OfficeLocationMapWidget(
                          latitude: _selectedLocation!.latitude,
                          longitude: _selectedLocation!.longitude,
                          address: _selectedAddress,
                          height: 200,
                          isInteractive: true,
                          onTap: _openLocationPicker,
                        ),
                        SizedBox(height: 12.h),
                        if (_selectedAddress.isNotEmpty)
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
                                  _selectedAddress,
                                  style: GoogleFonts.raleway(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ] else ...[
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_location_alt,
                                size: 40.sp,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'tap_to_set_office_location'.tr,
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
                                : 'set_office_location'.tr,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: BorderSide(color: AppColors.primaryColor),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.raleway(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.raleway(fontSize: 15.sp, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.raleway(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryColor, size: 22.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _consultationFeeController.dispose();
    _appointmentDurationController.dispose();
    super.dispose();
  }
}
