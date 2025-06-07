import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/doctor_entity.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';

class UserFormDialog extends StatefulWidget {
  final String userType; // 'patient' or 'doctor'
  final PatientEntity? patient; // For editing patient
  final DoctorEntity? doctor; // For editing doctor
  final bool isEditing;

  const UserFormDialog({
    Key? key,
    required this.userType,
    this.patient,
    this.doctor,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedGender = 'Homme';
  DateTime? _dateOfBirth;
  int? _age;

  // Patient specific fields
  final _antecedentController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String? _selectedBloodType;

  // Doctor specific fields
  final _specialityController = TextEditingController();
  final _licenceController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _educationController = TextEditingController();
  final _experienceController = TextEditingController();

  int _appointmentDuration = 30;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.isEditing) {
      if (widget.userType == 'patient' && widget.patient != null) {
        final patient = widget.patient!;
        _fullNameController.text = patient.fullName;
        _emailController.text = patient.email;
        _phoneController.text = patient.phoneNumber ?? '';
        _selectedGender = patient.gender ?? 'Homme';
        _dateOfBirth = patient.dateOfBirth;
        _age = patient.age;
        _antecedentController.text = patient.antecedent ?? '';
        _heightController.text = patient.height?.toString() ?? '';
        _weightController.text = patient.weight?.toString() ?? '';
        _allergiesController.text = patient.allergies?.join(', ') ?? '';
        _chronicDiseasesController.text =
            patient.chronicDiseases?.join(', ') ?? '';
        _emergencyNameController.text = patient.emergencyContactName ?? '';
        _emergencyPhoneController.text = patient.emergencyContactPhone ?? '';
        _selectedBloodType = patient.bloodType;
        _addressController.text = patient.address ?? '';
      } else if (widget.userType == 'doctor' && widget.doctor != null) {
        final doctor = widget.doctor!;
        _fullNameController.text = doctor.fullName;
        _emailController.text = doctor.email;
        _phoneController.text = doctor.phoneNumber ?? '';
        _selectedGender = doctor.gender ?? 'Homme';
        _dateOfBirth = doctor.dateOfBirth;
        _age = doctor.age;
        _specialityController.text = doctor.speciality ?? '';
        _licenceController.text = doctor.numLicence ?? '';
        _consultationFeeController.text =
            doctor.consultationFee?.toString() ?? '';
        _appointmentDuration = doctor.appointmentDuration;
        _educationController.text = doctor.educationSummary;
        _experienceController.text = doctor.experienceYears;
        _addressController.text = doctor.address ?? '';
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _antecedentController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _specialityController.dispose();
    _licenceController.dispose();
    _consultationFeeController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersBloc, UsersState>(
      listener: (context, state) {
        if (state is UserCreated || state is UserUpdated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is UserCreated
                    ? 'User created successfully'
                    : 'User updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is UserOperationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Dialog(
        child: Container(
          width: 600.w,
          height: 700.h,
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.isEditing ? 'Edit' : 'Add'} ${widget.userType == 'patient' ? 'Patient' : 'Doctor'}',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCommonFields(),
                        SizedBox(height: 20.h),
                        if (widget.userType == 'patient') _buildPatientFields(),
                        if (widget.userType == 'doctor') _buildDoctorFields(),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter full name';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        if (!widget.isEditing)
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        if (!widget.isEditing) SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items:
                    ['Homme', 'Femme'].map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _dateOfBirth ??
                  DateTime.now().subtract(Duration(days: 365 * 25)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _dateOfBirth = date;
                // Calculate age
                final now = DateTime.now();
                _age = now.year - date.year;
                if (now.month < date.month ||
                    (now.month == date.month && now.day < date.day)) {
                  _age = _age! - 1;
                }
              });
            }
          },
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Select Date of Birth',
                  style: TextStyle(fontSize: 16.sp),
                ),
                Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient Information',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _antecedentController,
          decoration: InputDecoration(
            labelText: 'Medical History (Antecedent)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedBloodType,
                decoration: InputDecoration(
                  labelText: 'Blood Type',
                  border: OutlineInputBorder(),
                ),
                items:
                    ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((
                      type,
                    ) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodType = value;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _allergiesController,
          decoration: InputDecoration(
            labelText: 'Allergies (comma separated)',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _chronicDiseasesController,
          decoration: InputDecoration(
            labelText: 'Chronic Diseases (comma separated)',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emergencyNameController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: TextFormField(
                controller: _emergencyPhoneController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoctorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doctor Information',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _specialityController,
                decoration: InputDecoration(
                  labelText: 'Speciality',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter speciality';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: TextFormField(
                controller: _licenceController,
                decoration: InputDecoration(
                  labelText: 'License Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter license number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _consultationFeeController,
                decoration: InputDecoration(
                  labelText: 'Consultation Fee',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _appointmentDuration,
                decoration: InputDecoration(
                  labelText: 'Appointment Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                items:
                    [15, 30, 45, 60, 90, 120].map((duration) {
                      return DropdownMenuItem(
                        value: duration,
                        child: Text('$duration min'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _appointmentDuration = value!;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _educationController,
          decoration: InputDecoration(
            labelText: 'Education',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _experienceController,
          decoration: InputDecoration(
            labelText: 'Experience',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final isLoading = state is UserOperationLoading;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            SizedBox(width: 16.w),
            ElevatedButton(
              onPressed: isLoading ? null : _submitForm,
              child:
                  isLoading
                      ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(widget.isEditing ? 'Update' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (widget.userType == 'patient') {
        _submitPatient();
      } else {
        _submitDoctor();
      }
    }
  }

  void _submitPatient() {
    final patient = PatientEntity(
      id: widget.isEditing ? widget.patient!.id : null,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      gender: _selectedGender,
      phoneNumber: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth,
      age: _age,
      address:
          _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
      accountStatus: true,
      antecedent:
          _antecedentController.text.trim().isNotEmpty
              ? _antecedentController.text.trim()
              : null,
      bloodType: _selectedBloodType,
      height:
          _heightController.text.isNotEmpty
              ? double.tryParse(_heightController.text)
              : null,
      weight:
          _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null,
      allergies:
          _allergiesController.text.isNotEmpty
              ? _allergiesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .toList()
              : null,
      chronicDiseases:
          _chronicDiseasesController.text.isNotEmpty
              ? _chronicDiseasesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .toList()
              : null,
      emergencyContactName:
          _emergencyNameController.text.trim().isNotEmpty
              ? _emergencyNameController.text.trim()
              : null,
      emergencyContactPhone:
          _emergencyPhoneController.text.trim().isNotEmpty
              ? _emergencyPhoneController.text.trim()
              : null,
      createdAt: widget.isEditing ? widget.patient!.createdAt : DateTime.now(),
      lastLogin: widget.isEditing ? widget.patient!.lastLogin : null,
    );

    if (widget.isEditing) {
      context.read<UsersBloc>().add(UpdatePatientEvent(patient: patient));
    } else {
      context.read<UsersBloc>().add(
        CreatePatientEvent(
          patient: patient,
          password: _passwordController.text,
        ),
      );
    }
  }

  void _submitDoctor() {
    final doctor = DoctorEntity(
      id: widget.isEditing ? widget.doctor!.id : null,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      gender: _selectedGender,
      phoneNumber: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth,
      age: _age,
      address:
          _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
      accountStatus: true,
      speciality:
          _specialityController.text.trim().isNotEmpty
              ? _specialityController.text.trim()
              : null,
      numLicence:
          _licenceController.text.trim().isNotEmpty
              ? _licenceController.text.trim()
              : null,
      appointmentDuration: _appointmentDuration,
      experienceYears:
          _experienceController.text.trim().isNotEmpty
              ? _experienceController.text.trim()
              : 'N/A',
      educationSummary:
          _educationController.text.trim().isNotEmpty
              ? _educationController.text.trim()
              : 'N/A',
      consultationFee:
          _consultationFeeController.text.isNotEmpty
              ? double.tryParse(_consultationFeeController.text)
              : null,
      createdAt: widget.isEditing ? widget.doctor!.createdAt : DateTime.now(),
      lastLogin: widget.isEditing ? widget.doctor!.lastLogin : null,
    );

    if (widget.isEditing) {
      context.read<UsersBloc>().add(UpdateDoctorEvent(doctor: doctor));
    } else {
      context.read<UsersBloc>().add(
        CreateDoctorEvent(doctor: doctor, password: _passwordController.text),
      );
    }
  }
}
