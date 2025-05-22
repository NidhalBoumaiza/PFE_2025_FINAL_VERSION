import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../../rendez_vous/domain/entities/rendez_vous_entity.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../data/models/medication_model.dart';

class CreatePrescriptionPage extends StatefulWidget {
  final RendezVousEntity appointment;
  final PatientEntity? patient;
  final PrescriptionEntity? existingPrescription;

  const CreatePrescriptionPage({
    Key? key,
    required this.appointment,
    this.patient,
    this.existingPrescription,
  }) : super(key: key);

  @override
  _CreatePrescriptionPageState createState() => _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState extends State<CreatePrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _noteController = TextEditingController();
  final List<MedicationModel> _medications = [];
  bool _isSaving = false;
  bool _isEditing = false;
  String? _prescriptionId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadExistingPrescription();
  }
  
  void _loadExistingPrescription() {
    if (widget.existingPrescription != null) {
      setState(() {
        _isEditing = true;
        _prescriptionId = widget.existingPrescription!.id;
        _noteController.text = widget.existingPrescription!.note ?? '';
        
        // Load medications from existing prescription
        for (var med in widget.existingPrescription!.medications) {
          _medications.add(MedicationModel.fromEntity(med));
        }
      });
    }
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addMedication() {
    if (_medicationNameController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _instructionsController.text.isEmpty) {
      showWarningSnackBar(
        context,
            'Veuillez remplir tous les champs pour le médicament',
      );
      return;
    }

    setState(() {
      _medications.add(
        MedicationModel(
          id: const Uuid().v4(),
          name: _medicationNameController.text,
          dosage: _dosageController.text,
          instructions: _instructionsController.text,
        ),
      );
      _medicationNameController.clear();
      _dosageController.clear();
      _instructionsController.clear();
    });
  }

  void _removeMedication(String id) {
    setState(() {
      _medications.removeWhere((medication) => medication.id == id);
    });
  }

  void _editMedication(MedicationModel medication) {
    _medicationNameController.text = medication.name;
    _dosageController.text = medication.dosage;
    _instructionsController.text = medication.instructions;
    
    _removeMedication(medication.id);
    
    // Scroll to medication form
    Future.delayed(Duration(milliseconds: 100), () {
      Scrollable.ensureVisible(
        _formKey.currentContext!,
        duration: Duration(milliseconds: 300),
      );
    });
  }

  Future<void> _savePrescription() async {
    if (_medications.isEmpty) {
      showWarningSnackBar(
        context,
            'Veuillez ajouter au moins un médicament',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Generate ID if it's a new prescription, otherwise use existing
      final prescriptionId = _isEditing ? _prescriptionId! : const Uuid().v4();
      final prescriptionData = {
        'id': prescriptionId,
        'appointmentId': widget.appointment.id,
        'patientId': widget.appointment.patientId,
        'patientName': widget.appointment.patientName,
        'doctorId': widget.appointment.doctorId,
        'doctorName': widget.appointment.doctorName,
        'date': _isEditing 
          ? widget.existingPrescription!.date.toIso8601String() 
          : DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'medications': _medications.map((m) => m.toJson()).toList(),
        'note': _noteController.text,
      };

      await _firestore.collection('prescriptions').doc(prescriptionId).set(prescriptionData);

      // Also update the appointment status to completed if needed
      if (widget.appointment.status != 'completed' && widget.appointment.id != null) {
        await _firestore.collection('rendez_vous').doc(widget.appointment.id).update({
          'status': 'completed',
        });
      }

      showSuccessSnackBar(
        context,
        _isEditing
          ? 'Ordonnance mise à jour avec succès'
          : 'Ordonnance enregistrée avec succès',
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving prescription: $e');
      showErrorSnackBar(
        context,
            'Erreur lors de l\'enregistrement: $e',
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? "Modifier l'ordonnance" : "Nouvelle Ordonnance",
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePrescription,
            child: _isSaving
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Enregistrer",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient information card
              _buildPatientInfoCard(),
              SizedBox(height: 20.h),

              // Medication list
              Text(
                "Médicaments",
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),

              // Existing medications
              ..._medications.map((medication) => _buildMedicationItem(medication)),

              // Add medication form
              _buildAddMedicationForm(),
              SizedBox(height: 20.h),

              // Additional notes
              Text(
                "Notes additionnelles",
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Notes ou instructions supplémentaires...",
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ),
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 100.h), // Extra space at bottom for keyboard
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _savePrescription,
        icon: Icon(Icons.save, color: Colors.white),
        label: Text(
          "Enregistrer",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 50.h,
                  width: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appointment.patientName ?? "Patient inconnu",
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(widget.appointment.startTime),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.patient != null && widget.patient!.antecedent.isNotEmpty) ...[
              Divider(height: 24.h),
              Text(
                "Antécédents médicaux:",
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.patient!.antecedent,
                style: GoogleFonts.raleway(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(MedicationModel medication) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    medication.name,
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryColor,
                    size: 22.sp,
                  ),
                  tooltip: "Modifier",
                  onPressed: () => _editMedication(medication),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22.sp,
                  ),
                  tooltip: "Supprimer",
                  onPressed: () => _removeMedication(medication.id),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 16.sp,
                  color: Colors.blueGrey,
                ),
                SizedBox(width: 6.w),
                Text(
                  "Dosage: ${medication.dosage}",
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16.sp,
                  color: Colors.blueGrey,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    "Instructions: ${medication.instructions}",
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMedicationForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ajouter un médicament",
                style: GoogleFonts.raleway(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _medicationNameController,
                decoration: InputDecoration(
                  labelText: 'Nom du médicament',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16.h),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addMedication,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Ajouter",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 