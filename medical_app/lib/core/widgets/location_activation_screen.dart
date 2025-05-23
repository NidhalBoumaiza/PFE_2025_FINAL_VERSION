import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationActivationScreen extends StatefulWidget {
  final Function? onLocationEnabled;

  const LocationActivationScreen({Key? key, this.onLocationEnabled})
    : super(key: key);

  @override
  State<LocationActivationScreen> createState() =>
      _LocationActivationScreenState();
}

class _LocationActivationScreenState extends State<LocationActivationScreen> {
  bool _showWidget1 = false;
  bool _showWidget2 = false;
  bool _showWidget3 = false;
  bool _showWidget4 = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _showWidgetsOneByOne();
  }

  void _showWidgetsOneByOne() {
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showWidget1 = true;
        });
      }
    });

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showWidget2 = true;
        });
      }
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showWidget3 = true;
        });
      }
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showWidget4 = true;
        });
      }
    });
  }

  Future<void> _enableLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        // Return and wait for user to enable location services
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Request permission
      LocationPermission permission =
          await LocationService.requestLocationPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        // Try to get position to confirm it works
        final position = await LocationService.getCurrentPosition();

        if (position != null) {
          // Success! Call the callback if provided
          if (widget.onLocationEnabled != null) {
            widget.onLocationEnabled!();
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('location_enabled_success'.tr),
              backgroundColor: Colors.green,
            ),
          );

          // Close this screen
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('could_not_get_location'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('location_permission_denied'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error enabling location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_enabling_location'.tr),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(30.w, 25.h, 30.w, 40.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50.h),
                  // Location map with animated pins
                  Stack(
                    children: [
                      // Base map image or color
                      Container(
                        height: 220.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20.r),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryColor.withOpacity(0.1),
                              Colors.blue.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/map_background.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Return empty container if image not found
                              return Container();
                            },
                          ),
                        ),
                      ),

                      // Animated location pins
                      // Pin 1
                      Positioned(
                        left: 60.w,
                        top: 45.h,
                        child: AnimatedOpacity(
                          opacity: _showWidget1 ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 500),
                          child: _buildLocationPin(AppColors.primaryColor),
                        ),
                      ),

                      // Pin 2
                      Positioned(
                        left: 165.w,
                        top: 55.h,
                        child: AnimatedOpacity(
                          opacity: _showWidget2 ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 500),
                          child: _buildLocationPin(Colors.red),
                        ),
                      ),

                      // Pin 3
                      Positioned(
                        left: 60.w,
                        top: 130.h,
                        child: AnimatedOpacity(
                          opacity: _showWidget3 ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 500),
                          child: _buildLocationPin(Colors.green),
                        ),
                      ),

                      // Pin 4
                      Positioned(
                        left: 165.w,
                        top: 130.h,
                        child: AnimatedOpacity(
                          opacity: _showWidget4 ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 500),
                          child: _buildLocationPin(Colors.orange),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),

                  // Title
                  Text(
                    'enable_location_settings'.tr,
                    style: GoogleFonts.raleway(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 25.h),

                  // Description
                  Text(
                    'location_required_for_map'.tr,
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 60.h),

                  // Enable location button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _enableLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2.w,
                                ),
                              )
                              : Text(
                                'allow'.tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'deny'.tr,
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
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

  Widget _buildLocationPin(Color color) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        Container(
          width: 15.w,
          height: 15.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
