import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';

class OfficeLocationMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? address;
  final double height;
  final bool isInteractive;
  final VoidCallback? onTap;

  const OfficeLocationMapWidget({
    Key? key,
    this.latitude,
    this.longitude,
    this.address,
    this.height = 200,
    this.isInteractive = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<OfficeLocationMapWidget> createState() =>
      _OfficeLocationMapWidgetState();
}

class _OfficeLocationMapWidgetState extends State<OfficeLocationMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setupMarker();
  }

  void _setupMarker() {
    if (widget.latitude != null && widget.longitude != null) {
      final location = LatLng(widget.latitude!, widget.longitude!);
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('office_location'),
            position: location,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Emplacement du cabinet',
              snippet: widget.address ?? 'Cabinet médical',
            ),
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.latitude == null || widget.longitude == null) {
      return Container(
        height: widget.height.h,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 48.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 8.h),
              Text(
                'Emplacement du cabinet non défini',
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              if (widget.onTap != null) ...[
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: widget.onTap,
                  child: Text(
                    'Définir l\'emplacement',
                    style: GoogleFonts.raleway(
                      fontSize: 12.sp,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final location = LatLng(widget.latitude!, widget.longitude!);

    return Container(
      height: widget.height.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: location,
                zoom: 15.0,
              ),
              markers: _markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: widget.isInteractive,
              zoomGesturesEnabled: widget.isInteractive,
              tiltGesturesEnabled: widget.isInteractive,
              rotateGesturesEnabled: widget.isInteractive,
              mapToolbarEnabled: false,
              onTap: widget.isInteractive ? (_) => widget.onTap?.call() : null,
            ),

            // Overlay for non-interactive maps
            if (!widget.isInteractive)
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(color: Colors.transparent),
                ),
              ),

            // Address overlay
            if (widget.address != null && widget.address!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    widget.address!,
                    style: GoogleFonts.raleway(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Edit button for interactive maps
            if (widget.isInteractive && widget.onTap != null)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: IconButton(
                    onPressed: widget.onTap,
                    icon: Icon(
                      Icons.edit_location,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 36.w,
                      minHeight: 36.h,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
