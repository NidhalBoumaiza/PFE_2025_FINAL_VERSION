import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final UserEntity user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _genderController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _antecedentController;
  late TextEditingController _specialityController;
  late TextEditingController _numLicenceController;
  late TextEditingController _appointmentDurationController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _consultationFeeController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneNumberController = TextEditingController(
      text: widget.user.phoneNumber,
    );
    _genderController = TextEditingController(text: widget.user.gender);
    _dateOfBirthController = TextEditingController(
      text:
          widget.user.dateOfBirth != null
              ? DateFormat('yyyy-MM-dd').format(widget.user.dateOfBirth!)
              : '',
    );

    // Initialize patient-specific controllers
    if (widget.user is PatientEntity) {
      final patient = widget.user as PatientEntity;
      _antecedentController = TextEditingController(
        text: patient.antecedent ?? '',
      );
      _bloodTypeController = TextEditingController(
        text: patient.bloodType ?? '',
      );
      _heightController = TextEditingController(
        text: patient.height?.toString() ?? '',
      );
      _weightController = TextEditingController(
        text: patient.weight?.toString() ?? '',
      );
      _allergiesController = TextEditingController(
        text: patient.allergies?.join(', ') ?? '',
      );

      // Initialize emergency contact controllers
      if (patient.emergencyContact != null) {
        _emergencyNameController = TextEditingController(
          text: patient.emergencyContact!['name'] ?? '',
        );
        _emergencyRelationController = TextEditingController(
          text: patient.emergencyContact!['relationship'] ?? '',
        );
        _emergencyPhoneController = TextEditingController(
          text: patient.emergencyContact!['phoneNumber'] ?? '',
        );
      } else {
        _emergencyNameController = TextEditingController();
        _emergencyRelationController = TextEditingController();
        _emergencyPhoneController = TextEditingController();
      }
    } else {
      _antecedentController = TextEditingController();
      _bloodTypeController = TextEditingController();
      _heightController = TextEditingController();
      _weightController = TextEditingController();
      _allergiesController = TextEditingController();
      _emergencyNameController = TextEditingController();
      _emergencyRelationController = TextEditingController();
      _emergencyPhoneController = TextEditingController();
    }

    // Initialize doctor-specific controllers
    if (widget.user is MedecinEntity) {
      final doctor = widget.user as MedecinEntity;
      _specialityController = TextEditingController(
        text: doctor.speciality ?? '',
      );
      _numLicenceController = TextEditingController(
        text: doctor.numLicence ?? '',
      );
      _appointmentDurationController = TextEditingController(
        text: doctor.appointmentDuration?.toString() ?? '30',
      );
      _consultationFeeController = TextEditingController(
        text: doctor.consultationFee?.toString() ?? '',
      );
    } else {
      _specialityController = TextEditingController();
      _numLicenceController = TextEditingController();
      _appointmentDurationController = TextEditingController();
      _consultationFeeController = TextEditingController();
    }

    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _phoneNumberController.addListener(_onFieldChanged);
    _genderController.addListener(_onFieldChanged);
    _dateOfBirthController.addListener(_onFieldChanged);
    _antecedentController.addListener(_onFieldChanged);
    _specialityController.addListener(_onFieldChanged);
    _numLicenceController.addListener(_onFieldChanged);
    _appointmentDurationController.addListener(_onFieldChanged);
    _bloodTypeController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _allergiesController.addListener(_onFieldChanged);
    _emergencyNameController.addListener(_onFieldChanged);
    _emergencyRelationController.addListener(_onFieldChanged);
    _emergencyPhoneController.addListener(_onFieldChanged);
    _consultationFeeController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _genderController.dispose();
    _dateOfBirthController.dispose();
    _antecedentController.dispose();
    _specialityController.dispose();
    _numLicenceController.dispose();
    _appointmentDurationController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      UserEntity updatedUser;
      if (widget.user is PatientEntity) {
        updatedUser = PatientEntity(
          id: widget.user.id,
          name: _nameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          role: widget.user.role,
          gender: _genderController.text,
          phoneNumber: _phoneNumberController.text,
          dateOfBirth:
              _dateOfBirthController.text.isNotEmpty
                  ? DateTime.tryParse(_dateOfBirthController.text)
                  : null,
          antecedent: _antecedentController.text,
          bloodType:
              _bloodTypeController.text.isNotEmpty
                  ? _bloodTypeController.text
                  : null,
          height:
              _heightController.text.isNotEmpty
                  ? double.tryParse(_heightController.text)
                  : null,
          weight:
              _weightController.text.isNotEmpty
                  ? double.parse(_weightController.text)
                  : null,
          allergies:
              _allergiesController.text.isNotEmpty
                  ? _allergiesController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList()
                  : null,
          emergencyContact:
              (_emergencyNameController.text.isNotEmpty ||
                      _emergencyRelationController.text.isNotEmpty ||
                      _emergencyPhoneController.text.isNotEmpty)
                  ? {
                    'name':
                        _emergencyNameController.text.isEmpty
                            ? null
                            : _emergencyNameController.text,
                    'relationship':
                        _emergencyRelationController.text.isEmpty
                            ? null
                            : _emergencyRelationController.text,
                    'phoneNumber':
                        _emergencyPhoneController.text.isEmpty
                            ? null
                            : _emergencyPhoneController.text,
                  }
                  : null,
        );
      } else {
        updatedUser = MedecinEntity(
          id: widget.user.id,
          name: _nameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          role: widget.user.role,
          gender: _genderController.text,
          phoneNumber: _phoneNumberController.text,
          dateOfBirth:
              _dateOfBirthController.text.isNotEmpty
                  ? DateTime.tryParse(_dateOfBirthController.text)
                  : null,
          speciality: _specialityController.text,
          numLicence: _numLicenceController.text,
          appointmentDuration:
              _appointmentDurationController.text.isNotEmpty
                  ? int.parse(_appointmentDurationController.text)
                  : 30,
          consultationFee:
              _consultationFeeController.text.isNotEmpty
                  ? double.parse(_consultationFeeController.text)
                  : null,
        );
      }
      Navigator.pop(context, updatedUser);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirthController.text.isNotEmpty
              ? DateTime.parse(_dateOfBirthController.text)
              : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: Colors.white,
              onSurface: AppColors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
        _hasChanges = true;
      });
    }
  }

  // Show a confirmation dialog when user tries to go back with unsaved changes
  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Discard Changes?',
              style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'You have unsaved changes. Are you sure you want to discard them?',
              style: GoogleFonts.raleway(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.raleway(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  'Discard',
                  style: GoogleFonts.raleway(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'edit_profile'.tr,
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: _saveChanges,
                tooltip: 'save'.tr,
              ),
          ],
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
                AppColors.primaryColor.withOpacity(0.1),
                Colors.white,
              ],
              stops: const [0.0, 0.1, 0.3, 0.5],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Profile picture & header
                SizedBox(
                  height: 120.h,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40.r,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40.sp,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          '${widget.user.name} ${widget.user.lastName}',
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form fields in scrollable area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.r),
                        topRight: Radius.circular(30.r),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20.w),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10.h),

                            Text(
                              'personal_information'.tr,
                              style: GoogleFonts.raleway(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // First Name field
                            _buildTextField(
                              controller: _nameController,
                              label: 'first_name_label'.tr,
                              icon: Icons.person,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'name_required'.tr
                                          : null,
                            ),
                            SizedBox(height: 16.h),

                            // Last Name field
                            _buildTextField(
                              controller: _lastNameController,
                              label: 'last_name_label'.tr,
                              icon: Icons.person,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'last_name_required'.tr
                                          : null,
                            ),
                            SizedBox(height: 16.h),

                            // Email field (disabled)
                            _buildTextField(
                              enabled: false,
                              controller: _emailController,
                              label: 'email'.tr,
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: 16.h),

                            // Phone Number field
                            _buildTextField(
                              controller: _phoneNumberController,
                              label: 'phone_number_label'.tr,
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'phone_number_required'.tr
                                          : null,
                            ),
                            SizedBox(height: 16.h),

                            // Gender field
                            _buildDropdownField(
                              controller: _genderController,
                              label: 'gender'.tr,
                              icon: Icons.people,
                              options: ['Male', 'Female', 'Other'],
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'gender_required'.tr
                                          : null,
                            ),
                            SizedBox(height: 16.h),

                            // Date of Birth field
                            _buildTextField(
                              controller: _dateOfBirthController,
                              label: 'date_of_birth_label'.tr,
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              hintText: 'YYYY-MM-DD',
                            ),

                            // Patient specific fields
                            if (widget.user is PatientEntity) ...[
                              SizedBox(height: 30.h),
                              Text(
                                'medical_information'.tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              _buildTextField(
                                controller: _antecedentController,
                                label: 'medical_history_label'.tr,
                                icon: Icons.medical_services,
                                maxLines: 3,
                                hintText: 'medical_history_hint'.tr,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                "blood_type".tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              _buildTextField(
                                controller: _bloodTypeController,
                                label: "blood_type".tr,
                                icon: Icons.bloodtype,
                                hintText: "select_blood_type".tr,
                              ),
                              SizedBox(height: 16.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _heightController,
                                      label: "height".tr,
                                      icon: Icons.height,
                                      keyboardType: TextInputType.number,
                                      hintText: "enter_height".tr,
                                      suffix: Text(
                                        "cm",
                                        style: GoogleFonts.raleway(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _weightController,
                                      label: "weight".tr,
                                      icon: Icons.monitor_weight,
                                      keyboardType: TextInputType.number,
                                      hintText: "enter_weight".tr,
                                      suffix: Text(
                                        "kg",
                                        style: GoogleFonts.raleway(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _allergiesController,
                                label: "allergies".tr,
                                icon: Icons.warning_amber,
                                hintText: "enter_allergies".tr,
                                maxLines: 2,
                              ),
                              SizedBox(height: 24.h),
                              Text(
                                "emergency_contact".tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _emergencyNameController,
                                label: "emergency_contact_name".tr,
                                icon: Icons.person,
                                hintText: "enter_emergency_name".tr,
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _emergencyRelationController,
                                label: "emergency_relationship".tr,
                                icon: Icons.people,
                                hintText: "enter_emergency_relationship".tr,
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _emergencyPhoneController,
                                label: "emergency_phone".tr,
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                hintText: "enter_emergency_phone".tr,
                              ),
                            ],

                            // Doctor specific fields
                            if (widget.user is MedecinEntity) ...[
                              SizedBox(height: 30.h),
                              Text(
                                'professional_information'.tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              _buildTextField(
                                controller: _specialityController,
                                label: 'specialty_label'.tr,
                                icon: Icons.medical_services,
                                validator:
                                    (value) =>
                                        value!.isEmpty
                                            ? 'specialty_required'.tr
                                            : null,
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _numLicenceController,
                                label: 'license_number_label'.tr,
                                icon: Icons.badge,
                                validator:
                                    (value) =>
                                        value!.isEmpty
                                            ? 'license_number_required'.tr
                                            : null,
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _appointmentDurationController,
                                label: 'appointment_duration'.tr,
                                icon: Icons.timer,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value!.isEmpty)
                                    return 'appointment_duration_required'.tr;
                                  final duration = int.tryParse(value);
                                  if (duration == null || duration <= 0) {
                                    return 'Please enter a valid duration';
                                  }
                                  return null;
                                },
                                suffix: Text(
                                  'minutes'.tr,
                                  style: GoogleFonts.raleway(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _consultationFeeController,
                                label: "consultation_fee_label".tr,
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                hintText: "consultation_fee_hint".tr,
                              ),
                            ],

                            SizedBox(height: 40.h),

                            // Save button
                            Container(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _hasChanges ? _saveChanges : null,
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
                                child: Text(
                                  'save'.tr,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
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
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: GoogleFonts.raleway(fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          suffixIcon: suffix,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> options,
    String? Function(String?)? validator,
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
        value: options.contains(controller.text) ? controller.text : null,
        items:
            options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
            _hasChanges = true;
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.raleway(color: AppColors.primaryColor),
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
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
        style: GoogleFonts.raleway(fontSize: 14.sp),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
      ),
    );
  }
}
