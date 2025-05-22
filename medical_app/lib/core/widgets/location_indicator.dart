import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationIndicator extends StatefulWidget {
  final VoidCallback? onTap;
  final String? userId;
  final bool isDarkMode;

  const LocationIndicator({
    Key? key,
    this.onTap,
    this.userId,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<LocationIndicator> createState() => _LocationIndicatorState();
}

class _LocationIndicatorState extends State<LocationIndicator> {
  bool _isLocationEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    try {
      final serviceEnabled = await LocationService.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      setState(() {
        _isLocationEnabled =
            serviceEnabled &&
            (permission == LocationPermission.always ||
                permission == LocationPermission.whileInUse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLocationEnabled = false;
        _isLoading = false;
      });
      print('Error checking location status: $e');
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      _showLocationPermissionDialog();
    }
  }

  void _showLocationPermissionDialog() async {
    final serviceEnabled = await LocationService.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    final permission = await LocationService.requestLocationPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() {
        _isLocationEnabled = true;
      });

      // Update location if userId is provided
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        await LocationService.updateUserLocation(widget.userId!, 'patient');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color:
              _isLocationEnabled
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isLocationEnabled ? AppColors.primaryColor : Colors.grey,
                  ),
                ),
              )
            else
              Icon(
                _isLocationEnabled ? Icons.location_on : Icons.location_off,
                color:
                    _isLocationEnabled ? AppColors.primaryColor : Colors.grey,
                size: 16.sp,
              ),
            SizedBox(width: 4.w),
            Text(
              _isLocationEnabled
                  ? 'location_enabled'.tr
                  : 'location_disabled'.tr,
              style: GoogleFonts.raleway(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color:
                    _isLocationEnabled ? AppColors.primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
