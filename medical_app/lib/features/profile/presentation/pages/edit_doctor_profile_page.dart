import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/location_picker_widget.dart';
import '../../../../core/widgets/office_location_map_widget.dart';
import '../../../authentication/domain/entities/medecin_entity.dart';
import '../../../authentication/data/models/medecin_model.dart';
import 'blocs/BLoC update profile/update_user_bloc.dart';

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
              title: 'Modifier l\'emplacement du cabinet',
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

      // Create updated doctor model using MedecinModel to ensure all fields are preserved
      final updatedDoctor = MedecinModel(
        id: widget.doctor.id,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: widget.doctor.email,
        role: widget.doctor.role,
        gender: widget.doctor.gender,
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: widget.doctor.dateOfBirth,
        speciality: widget.doctor.speciality ?? '',
        numLicence: widget.doctor.numLicence ?? '',
        appointmentDuration:
            int.tryParse(_appointmentDurationController.text) ?? 30,
        consultationFee: double.tryParse(_consultationFeeController.text),
        education: widget.doctor.education,
        experience: widget.doctor.experience,
        location: locationData ?? widget.doctor.location,
        address: addressData ?? widget.doctor.address,
        accountStatus: widget.doctor.accountStatus,
        verificationCode: widget.doctor.verificationCode,
        validationCodeExpiresAt: widget.doctor.validationCodeExpiresAt,
        fcmToken: widget.doctor.fcmToken,
      );

      // Dispatch update event to BLoC
      context.read<UpdateUserBloc>().add(UpdateUserEvent(updatedDoctor));
    } catch (e) {
      // Show error message
      Get.snackbar(
        'Erreur',
        'Erreur lors de la mise à jour du profil',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier le profil',
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
      ),
      body: BlocConsumer<UpdateUserBloc, UpdateUserState>(
        listener: (context, state) {
          if (state is UpdateUserSuccess) {
            // Show success message
            Get.snackbar(
              'Succès',
              'Profil mis à jour avec succès',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );

            // Return to previous screen with updated doctor data
            Navigator.of(context).pop(state.user);
          } else if (state is UpdateUserFailure) {
            // Show error message
            Get.snackbar(
              'Erreur',
              state.message,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is UpdateUserLoading;

          return SingleChildScrollView(
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
                          widget.doctor.speciality ??
                              'Spécialité non spécifiée',
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
                  _buildSectionTitle('Informations personnelles'),
                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _nameController,
                    label: 'Prénom',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le prénom est requis';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Nom',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est requis';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'Numéro de téléphone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le numéro de téléphone est requis';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Professional Information Section
                  _buildSectionTitle('Informations professionnelles'),
                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _consultationFeeController,
                    label: 'Tarif de consultation',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Tarif de consultation invalide';
                        }
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  _buildTextField(
                    controller: _appointmentDurationController,
                    label: 'Durée du rendez-vous',
                    icon: Icons.schedule,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La durée du rendez-vous est requise';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Durée du rendez-vous invalide';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Office Location Section
                  _buildSectionTitle('Emplacement du cabinet'),
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
                                    'Appuyez pour définir l\'emplacement du cabinet',
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
                                    ? 'Modifier l\'emplacement'
                                    : 'Définir l\'emplacement du cabinet',
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

                  // Save Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: !isLoading ? _saveProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 2,
                      ),
                      child:
                          isLoading
                              ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Sauvegarder',
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
