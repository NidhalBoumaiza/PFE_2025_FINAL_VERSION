import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:geolocator/geolocator.dart';

class SimpleMapTest extends StatefulWidget {
  const SimpleMapTest({super.key});

  @override
  State<SimpleMapTest> createState() => SimpleMapTestState();
}

class SimpleMapTestState extends State<SimpleMapTest> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Using Tunis coordinates instead of Google Plex
  static const CameraPosition _kTunis = CameraPosition(
    target: LatLng(36.8189, 10.1657),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(36.8289, 10.1757),
    tilt: 59.440717697143555,
    zoom: 19.151926040649414,
  );

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle permission denied
        print('Location permission denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Handle permission permanently denied
      print('Location permission permanently denied');
      return;
    }
    // Permission granted, proceed with map
    print('Location permission granted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test simple de Google Maps',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kTunis,
        onMapCreated: (GoogleMapController controller) {
          print('🎉 Simple Map Created Successfully!');
          _controller.complete(controller);
        },
        markers: {
          const Marker(
            markerId: MarkerId('tunis_marker'),
            position: LatLng(36.8189, 10.1657),
            infoWindow: InfoWindow(
              title: 'Tunis',
              snippet: 'Capital of Tunisia',
            ),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('Déplacer la caméra'),
        icon: const Icon(Icons.directions_boat),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
