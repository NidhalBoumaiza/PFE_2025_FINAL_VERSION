import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../../authentication/data/models/patient_model.dart';
import 'blocs/BLoC update profile/update_user_bloc.dart';

class EditPatientProfilePage extends StatefulWidget {
  final PatientEntity patient;

  const EditPatientProfilePage({Key? key, required this.patient})
    : super(key: key);

  @override
  State<EditPatientProfilePage> createState() => _EditPatientProfilePageState();
}

class _EditPatientProfilePageState extends State<EditPatientProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _chronicDiseasesController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationController;
  late TextEditingController _emergencyPhoneController;

  String? _selectedGender;
  String? _selectedBloodType;
  bool _hasChanges = false;

  final List<String> _genders = ['male', 'female'];
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Gender mapping to handle different stored values
  String? _mapGenderToKey(String? gender) {
    if (gender == null || gender.isEmpty) return null;

    // Handle different possible stored values
    switch (gender.toLowerCase()) {
      case 'male':
      case 'homme':
      case 'ذكر':
        return 'male';
      case 'female':
      case 'femme':
      case 'أنثى':
        return 'female';
      default:
        return gender.toLowerCase();
    }
  }

  String? _mapKeyToDisplayValue(String? key) {
    if (key == null) return null;
    return key.tr;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(
      text: widget.patient.name ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.patient.lastName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.patient.phoneNumber ?? '',
    );
    _dateOfBirthController = TextEditingController(
      text:
          widget.patient.dateOfBirth != null
              ? DateFormat('dd/MM/yyyy').format(widget.patient.dateOfBirth!)
              : '',
    );
    _heightController = TextEditingController(
      text: widget.patient.height?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.patient.weight?.toString() ?? '',
    );
    _allergiesController = TextEditingController(
      text: widget.patient.allergies?.join(', ') ?? '',
    );
    _chronicDiseasesController = TextEditingController(
      text: widget.patient.chronicDiseases?.join(', ') ?? '',
    );

    // Handle emergency contact as Map
    _emergencyNameController = TextEditingController(
      text: widget.patient.emergencyContact?['name'] ?? '',
    );
    _emergencyRelationController = TextEditingController(
      text: widget.patient.emergencyContact?['relationship'] ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: widget.patient.emergencyContact?['phoneNumber'] ?? '',
    );

    _selectedGender = _mapGenderToKey(widget.patient.gender);
    _selectedBloodType = widget.patient.bloodType;

    // Add listeners to detect changes
    _addChangeListeners();
  }

  void _addChangeListeners() {
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _dateOfBirthController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _allergiesController.addListener(_onFieldChanged);
    _chronicDiseasesController.addListener(_onFieldChanged);
    _emergencyNameController.addListener(_onFieldChanged);
    _emergencyRelationController.addListener(_onFieldChanged);
    _emergencyPhoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          widget.patient.dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
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

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Parse date
      DateTime? dateOfBirth;
      if (_dateOfBirthController.text.isNotEmpty) {
        try {
          dateOfBirth = DateFormat(
            'dd/MM/yyyy',
          ).parse(_dateOfBirthController.text);
        } catch (e) {
          // Handle date parsing error
        }
      }

      // Parse allergies and chronic diseases
      List<String>? allergies =
          _allergiesController.text.isNotEmpty
              ? _allergiesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
              : null;

      List<String>? chronicDiseases =
          _chronicDiseasesController.text.isNotEmpty
              ? _chronicDiseasesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
              : null;

      // Create emergency contact map
      Map<String, String?>? emergencyContact;
      if (_emergencyNameController.text.trim().isNotEmpty ||
          _emergencyRelationController.text.trim().isNotEmpty ||
          _emergencyPhoneController.text.trim().isNotEmpty) {
        emergencyContact = {
          'name':
              _emergencyNameController.text.trim().isNotEmpty
                  ? _emergencyNameController.text.trim()
                  : null,
          'relationship':
              _emergencyRelationController.text.trim().isNotEmpty
                  ? _emergencyRelationController.text.trim()
                  : null,
          'phoneNumber':
              _emergencyPhoneController.text.trim().isNotEmpty
                  ? _emergencyPhoneController.text.trim()
                  : null,
        };
      }

      // Create updated patient model using PatientModel to ensure all fields are preserved
      final updatedPatient = PatientModel(
        id: widget.patient.id,
        name: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: widget.patient.email,
        role: widget.patient.role,
        gender: _selectedGender ?? widget.patient.gender,
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: dateOfBirth,
        antecedent: widget.patient.antecedent ?? '',
        bloodType: _selectedBloodType,
        height:
            _heightController.text.isNotEmpty
                ? double.tryParse(_heightController.text)
                : null,
        weight:
            _weightController.text.isNotEmpty
                ? double.tryParse(_weightController.text)
                : null,
        allergies: allergies ?? [],
        chronicDiseases: chronicDiseases ?? [],
        emergencyContact: emergencyContact,
        address: widget.patient.address,
        location: widget.patient.location,
        accountStatus: widget.patient.accountStatus,
        verificationCode: widget.patient.verificationCode,
        validationCodeExpiresAt: widget.patient.validationCodeExpiresAt,
        fcmToken: widget.patient.fcmToken,
      );

      // Dispatch update event to BLoC
      context.read<UpdateUserBloc>().add(UpdateUserEvent(updatedPatient));
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Modifier le profil',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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

            // Return to previous screen with updated patient data
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

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section
                  _buildSectionHeader(
                    'Informations personnelles',
                    Icons.person,
                  ),
                  SizedBox(height: 20.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: 'Prénom',
                          icon: Icons.person_outline,
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Le prénom est requis'
                                      : null,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: 'Nom',
                          icon: Icons.person_outline,
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Le nom est requis' : null,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Numéro de téléphone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Le numéro de téléphone est requis'
                                : null,
                  ),

                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _dateOfBirthController,
                    label: 'Date de naissance',
                    icon: Icons.calendar_today,
                    readOnly: true,
                    onTap: _selectDate,
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'La date de naissance est requise'
                                : null,
                  ),

                  SizedBox(height: 16.h),
                  _buildDropdownField(
                    value: _selectedGender,
                    label: 'Sexe',
                    icon: Icons.wc,
                    items: _genders,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                        _hasChanges = true;
                      });
                    },
                  ),

                  // Medical Information Section
                  SizedBox(height: 30.h),
                  _buildSectionHeader(
                    'Informations médicales',
                    Icons.medical_services,
                  ),
                  SizedBox(height: 20.h),

                  _buildDropdownField(
                    value: _selectedBloodType,
                    label: 'Groupe sanguin',
                    icon: Icons.bloodtype,
                    items: _bloodTypes,
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodType = value;
                        _hasChanges = true;
                      });
                    },
                  ),

                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'Taille',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                          suffix: Text(
                            'cm',
                            style: GoogleFonts.raleway(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'Poids',
                          icon: Icons.monitor_weight,
                          keyboardType: TextInputType.number,
                          suffix: Text(
                            'kg',
                            style: GoogleFonts.raleway(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _allergiesController,
                    label: 'Allergies',
                    icon: Icons.warning,
                    hintText: 'Entrez vos allergies séparées par des virgules',
                    maxLines: 2,
                  ),

                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _chronicDiseasesController,
                    label: 'Maladies chroniques',
                    icon: Icons.local_hospital,
                    hintText:
                        'Entrez vos maladies chroniques séparées par des virgules',
                    maxLines: 2,
                  ),

                  // Emergency Contact Section
                  SizedBox(height: 30.h),
                  _buildSectionHeader('Contact d\'urgence', Icons.emergency),
                  SizedBox(height: 20.h),

                  _buildTextField(
                    controller: _emergencyNameController,
                    label: 'Nom du contact d\'urgence',
                    icon: Icons.person,
                    hintText: 'Entrez le nom du contact d\'urgence',
                  ),

                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _emergencyRelationController,
                    label: 'Relation',
                    icon: Icons.people,
                    hintText: 'Ex: Époux/Épouse, Parent, Ami',
                  ),

                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _emergencyPhoneController,
                    label: 'Téléphone d\'urgence',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    hintText: 'Entrez le numéro de téléphone d\'urgence',
                  ),

                  // Save Button
                  SizedBox(height: 40.h),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_hasChanges && !isLoading) ? _saveChanges : null,
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
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 24.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: GoogleFonts.raleway(fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: GoogleFonts.raleway(color: AppColors.primaryColor),
          hintStyle: GoogleFonts.raleway(color: Colors.grey[400]),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 16.w,
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
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          suffixIcon:
              suffix != null
                  ? Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: suffix,
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        style: GoogleFonts.raleway(fontSize: 14.sp, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.raleway(color: AppColors.primaryColor),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 16.w,
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
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
        ),
        items:
            items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item.tr,
                  style: GoogleFonts.raleway(fontSize: 14.sp),
                ),
              );
            }).toList(),
      ),
    );
  }
}
