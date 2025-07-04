import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/ratings/presentation/bloc/rating_bloc.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/features/rendez_vous/presentation/pages/doctor_profile_page.dart';
import 'package:medical_app/core/services/location_service.dart';
import 'package:intl/intl.dart';

class AvailableDoctorsScreen extends StatefulWidget {
  final String specialty;
  final DateTime startTime;
  final String patientId;
  final String patientName;

  const AvailableDoctorsScreen({
    Key? key,
    required this.specialty,
    required this.startTime,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  State<AvailableDoctorsScreen> createState() => _AvailableDoctorsScreenState();
}

class _AvailableDoctorsScreenState extends State<AvailableDoctorsScreen> {
  final Map<String, double> _doctorRatings = {};
  bool _isLoading = false;
  double _searchRadius = 10.0; // Default 10 km
  double? _userLatitude;
  double? _userLongitude;
  bool _isLocationLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
          _isLocationLoading = false;
        });
        _fetchDoctors();
      } else {
        setState(() {
          _isLocationLoading = false;
        });
        _fetchDoctors(); // Fetch without location filtering
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLocationLoading = false;
      });
      _fetchDoctors(); // Fetch without location filtering
    }
  }

  void _fetchDoctors() {
    context.read<RendezVousBloc>().add(
      FetchDoctorsBySpecialty(
        widget.specialty,
        widget.startTime,
        searchRadiusKm:
            _userLatitude != null && _userLongitude != null
                ? _searchRadius
                : null,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
      ),
    );
  }

  void _loadDoctorRating(String doctorId) {
    // Load doctor's average rating
    context.read<RatingBloc>().add(GetDoctorAverageRating(doctorId));
  }

  void _navigateToDoctorProfile(MedecinEntity doctor) {
    navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
      context,
      DoctorProfilePage(
        doctor: doctor,
        canBookAppointment: true,
        onBookAppointment: () {
          Navigator.pop(context);
          _confirmRendezVous(context, doctor);
        },
      ),
    );
  }

  Future<void> _confirmRendezVous(
    BuildContext context,
    MedecinEntity doctor,
  ) async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final formattedDate = DateFormat(
      'dd/MM/yyyy à HH:mm',
    ).format(widget.startTime);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirmer la consultation',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            content: Text(
              'Confirmer la consultation avec Dr. ${doctor.name} ${doctor.lastName} le $formattedDate ?',
              style: GoogleFonts.raleway(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            backgroundColor: theme.dialogTheme.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.raleway(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Confirmer',
                  style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final rendezVous = RendezVousEntity(
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorId: doctor.id,
        doctorName: '${doctor.name} ${doctor.lastName}',
        speciality: widget.specialty,
        startTime: widget.startTime,
        status: 'pending',
      );
      context.read<RendezVousBloc>().add(CreateRendezVous(rendezVous));
    }
  }

  void _showRangeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        double tempRadius = _searchRadius;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Rayon de recherche',
                    style: GoogleFonts.raleway(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primaryColor),
                      SizedBox(width: 8.w),
                      Text(
                        'Rayon de recherche',
                        style: GoogleFonts.raleway(fontSize: 16.sp),
                      ),
                      Spacer(),
                      Text(
                        '${tempRadius.toInt()} km',
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Slider(
                    value: tempRadius,
                    min: 0.0,
                    max: 100.0,
                    divisions: 100,
                    activeColor: AppColors.primaryColor,
                    inactiveColor: AppColors.primaryColor.withOpacity(0.3),
                    onChanged: (value) {
                      setModalState(() {
                        tempRadius = value;
                      });
                    },
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0 km',
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '100 km',
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  if (_userLatitude == null || _userLongitude == null)
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Localisation non disponible, recherche dans toute la région',
                              style: GoogleFonts.raleway(fontSize: 14.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: BorderSide(color: AppColors.primaryColor),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.raleway(fontSize: 16.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchRadius = tempRadius;
                            });
                            Navigator.pop(context);
                            _fetchDoctors();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Appliquer',
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Médecins disponibles',
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: Colors.white),
            onPressed: _showRangeSelector,
            tooltip: 'Rayon de recherche',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.specialty,
                  style: GoogleFonts.raleway(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Rendez-vous le ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.startTime)}',
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 8.h),
                // Location and search radius info
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _userLatitude != null && _userLongitude != null
                            ? Icons.location_on
                            : Icons.location_off,
                        color: AppColors.primaryColor,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _userLatitude != null && _userLongitude != null
                              ? 'Recherche dans un rayon de ${_searchRadius.toInt()} km'
                              : 'Recherche de tous les médecins',
                          style: GoogleFonts.raleway(
                            fontSize: 12.sp,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      if (_userLatitude != null && _userLongitude != null)
                        GestureDetector(
                          onTap: _showRangeSelector,
                          child: Text(
                            'Modifier',
                            style: GoogleFonts.raleway(
                              fontSize: 12.sp,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                _isLocationLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Obtention de la localisation',
                            style: GoogleFonts.raleway(fontSize: 16.sp),
                          ),
                        ],
                      ),
                    )
                    : BlocConsumer<RendezVousBloc, RendezVousState>(
                      listener: (context, state) {
                        if (state is RendezVousError) {
                          if (_isLoading) {
                            Navigator.of(context).pop();
                            setState(() => _isLoading = false);
                          }
                          showErrorSnackBar(context, state.message);
                        } else if (state is RendezVousErrorState) {
                          if (_isLoading) {
                            Navigator.of(context).pop();
                            setState(() => _isLoading = false);
                          }
                          showErrorSnackBar(context, state.message);
                        } else if (state is AddingRendezVousState) {
                          setState(() => _isLoading = true);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: AppColors.primaryColor,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Création du rendez-vous',
                                        style: GoogleFonts.raleway(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } else if (state is RendezVousCreated) {
                          if (_isLoading) {
                            Navigator.of(context).pop();
                            setState(() => _isLoading = false);
                          }

                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);

                          showSuccessSnackBar(
                            context,
                            'Demande de consultation envoyée',
                          );
                        } else if (state is DoctorsLoaded) {
                          for (var doctor in state.doctors) {
                            if (doctor.id != null) {
                              _loadDoctorRating(doctor.id!);
                            }
                          }
                        }
                      },
                      builder: (context, state) {
                        if (state is RendezVousLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          );
                        } else if (state is DoctorsLoaded) {
                          final doctors = state.doctors;
                          if (doctors.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64.sp,
                                      color:
                                          isDarkMode
                                              ? theme.iconTheme.color
                                                  ?.withOpacity(0.4)
                                              : Colors.grey[400],
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Aucun médecin disponible',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.raleway(
                                        fontSize: 16.sp,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.all(12.w),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              return _buildDoctorCard(doctor);
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(MedecinEntity doctor) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDoctorProfile(doctor),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 60.h,
                    width: 60.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.person, color: Colors.white, size: 32.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. ${doctor.name} ${doctor.lastName}",
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          doctor.speciality ?? "",
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        BlocListener<RatingBloc, RatingState>(
                          listener: (context, state) {
                            if (state is DoctorRatingState &&
                                doctor.id != null) {
                              setState(() {
                                _doctorRatings[doctor.id!] =
                                    state.averageRating;
                              });
                            } else if (state is DoctorAverageRatingLoaded &&
                                doctor.id != null) {
                              setState(() {
                                _doctorRatings[doctor.id!] =
                                    state.averageRating;
                              });
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _doctorRatings.containsKey(doctor.id)
                                    ? _doctorRatings[doctor.id]!
                                        .toStringAsFixed(1)
                                    : "N/A",
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.info_outline, size: 18.sp),
                    label: Text(
                      "Voir le profil",
                      style: GoogleFonts.raleway(fontSize: 14.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    onPressed: () => _navigateToDoctorProfile(doctor),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.calendar_today, size: 18.sp),
                      label: Text(
                        "Sélectionner",
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _confirmRendezVous(context, doctor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
