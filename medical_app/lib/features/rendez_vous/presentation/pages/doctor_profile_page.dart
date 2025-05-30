import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/office_location_map_widget.dart';
import '../../../authentication/domain/entities/medecin_entity.dart';
import '../../../ratings/domain/entities/doctor_rating_entity.dart';
import '../../../ratings/presentation/bloc/rating_bloc.dart';

class DoctorProfilePage extends StatefulWidget {
  final MedecinEntity doctor;
  final bool canBookAppointment;
  final VoidCallback? onBookAppointment;

  const DoctorProfilePage({
    Key? key,
    required this.doctor,
    this.canBookAppointment = false,
    this.onBookAppointment,
  }) : super(key: key);

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  double _averageRating = 0.0;
  int _ratingCount = 0;
  bool _isLoading = true;
  List<DoctorRatingEntity> _ratings = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    if (widget.doctor.id != null) {
      _loadDoctorRatingsDirectly();
    }
  }

  Future<void> _loadDoctorRatingsDirectly() async {
    if (widget.doctor.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Get ratings count and calculate average
      final QuerySnapshot ratingSnapshot =
          await _firestore
              .collection('doctor_ratings')
              .where('doctorId', isEqualTo: widget.doctor.id)
              .get();

      // Calculate total rating and count
      double totalRating = 0.0;
      final docs = ratingSnapshot.docs;

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('rating')) {
          totalRating += (data['rating'] as num).toDouble();
        }
      }

      // 2. Get the actual rating documents for display
      final List<DoctorRatingEntity> ratings = [];
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Convert Timestamp to DateTime
        DateTime createdAt;
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else {
          createdAt = DateTime.now(); // Fallback if createdAt is missing
        }

        ratings.add(
          DoctorRatingEntity(
            id: doc.id,
            doctorId: data['doctorId'],
            patientId: data['patientId'],
            patientName: data['patientName'],
            rating: (data['rating'] as num).toDouble(),
            comment: data['comment'],
            createdAt: createdAt,
            rendezVousId: data['rendezVousId'],
          ),
        );
      }

      // Sort ratings by date (newest first)
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _ratingCount = docs.length;
        _averageRating = _ratingCount > 0 ? totalRating / _ratingCount : 0.0;
        _ratings = ratings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading doctor ratings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "doctor_profile".tr,
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor header card with basic info
            _buildDoctorHeaderCard(),

            // Office Location section
            _buildOfficeLocationSection(),

            // Ratings section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                "reviews".tr,
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),

            // Rating summary
            _isLoading
                ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
                : _buildRatingSummary(_averageRating, _ratingCount),

            // Patient comments
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Text(
                "Commentaires",
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),

            // Comments list
            _isLoading
                ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
                : _ratings.isEmpty
                ? Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Center(
                    child: Text(
                      "no_reviews_available".tr,
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _ratings.length,
                  itemBuilder: (context, index) {
                    return _buildRatingItem(_ratings[index]);
                  },
                ),

            SizedBox(height: 100.h), // Extra space at bottom for FAB
          ],
        ),
      ),
      floatingActionButton:
          widget.canBookAppointment
              ? FloatingActionButton.extended(
                onPressed: widget.onBookAppointment,
                icon: Icon(Icons.calendar_today),
                label: Text("book_appointment".tr),
                backgroundColor: AppColors.primaryColor,
              )
              : null,
    );
  }

  Widget _buildDoctorHeaderCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.all(16.w),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 80.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 40.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. ${widget.doctor.name} ${widget.doctor.lastName}",
                        style: GoogleFonts.raleway(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.doctor.speciality ??
                            "specialty_not_specified".tr,
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Divider(height: 24.h),

            // Contact info
            _buildInfoRow(
              Icons.phone,
              widget.doctor.phoneNumber ?? "not_specified".tr,
            ),
            _buildInfoRow(
              Icons.mail,
              widget.doctor.email ?? "not_specified".tr,
            ),
            _buildInfoRow(Icons.location_on, "address_not_specified".tr),

            // Add consultation fee if available
            if (widget.doctor.consultationFee != null)
              _buildInfoRow(
                Icons.attach_money,
                "${widget.doctor.consultationFee} ${"currency".tr}",
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primaryColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(double averageRating, int ratingCount) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              RatingBar.builder(
                initialRating: averageRating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20.sp,
                ignoreGestures: true,
                unratedColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                itemBuilder:
                    (context, _) => Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (_) {},
              ),
              SizedBox(height: 4.h),
              Text(
                "$ratingCount ${"evaluations".tr}",
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          Spacer(),
          CircleAvatar(
            radius: 26.r,
            backgroundColor: AppColors.primaryColor,
            child: Icon(Icons.star, color: Colors.white, size: 24.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(DoctorRatingEntity rating) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      isDarkMode ? theme.colorScheme.surface : Colors.grey[200],
                  radius: 20.r,
                  child: Text(
                    (rating.patientName != null &&
                            rating.patientName!.isNotEmpty)
                        ? rating.patientName![0].toUpperCase()
                        : "?",
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.patientName ?? "",
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(rating.createdAt),
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      rating.rating.toString(),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                rating.comment!,
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeLocationSection() {
    final theme = Theme.of(context);

    // Extract location data from doctor entity
    double? latitude;
    double? longitude;
    String? address;

    if (widget.doctor.location != null) {
      // Handle both old format (separate lat/lng fields) and new GeoJSON format
      if (widget.doctor.location!.containsKey('coordinates') &&
          widget.doctor.location!['coordinates'] is List) {
        // New GeoJSON format: [longitude, latitude]
        final coordinates = widget.doctor.location!['coordinates'] as List;
        if (coordinates.length >= 2) {
          longitude = (coordinates[0] as num?)?.toDouble();
          latitude = (coordinates[1] as num?)?.toDouble();
        }
      } else {
        // Old format: separate latitude and longitude fields
        latitude = widget.doctor.location!['latitude']?.toDouble();
        longitude = widget.doctor.location!['longitude']?.toDouble();
      }
    }

    if (widget.doctor.address != null) {
      address =
          widget.doctor.address!['formatted_address'] ??
          widget.doctor.address!['coordinates'];
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "office_location".tr,
            style: GoogleFonts.raleway(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 12.h),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OfficeLocationMapWidget(
                    latitude: latitude,
                    longitude: longitude,
                    address: address,
                    height: 200,
                    isInteractive: false,
                    onTap:
                        latitude != null && longitude != null
                            ? () {
                              // Open in external map app
                              _openInMaps(latitude!, longitude!, address);
                            }
                            : null,
                  ),
                  if (address != null && address.isNotEmpty) ...[
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
                            address,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (latitude != null && longitude != null) ...[
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _openInMaps(latitude!, longitude!, address),
                        icon: Icon(Icons.directions, size: 18.sp),
                        label: Text(
                          'get_directions'.tr,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openInMaps(double latitude, double longitude, String? address) {
    // This would typically open the location in the device's default map app
    // For now, we'll show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('opening_in_maps'.tr, style: GoogleFonts.raleway()),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
