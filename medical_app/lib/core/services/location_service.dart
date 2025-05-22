import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class LocationService {
  static const String LOCATION_PERMISSION_KEY = 'location_permission_granted';

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(LOCATION_PERMISSION_KEY) ?? false;
  }

  // Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    final prefs = await SharedPreferences.getInstance();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await prefs.setBool(LOCATION_PERMISSION_KEY, true);
    } else {
      await prefs.setBool(LOCATION_PERMISSION_KEY, false);
    }

    return permission;
  }

  // Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Update user location in Firestore
  static Future<bool> updateUserLocation(String userId, String userType) async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return false;

      final locationData = {
        'type': 'Point',
        'coordinates': [position.longitude, position.latitude],
      };

      // Determine collection based on user type
      final collection = userType == 'patient' ? 'patients' : 'medecins';

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .update({'location': locationData});

      // Also update in shared preferences for cached user
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('CACHED_USER');
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        userMap['location'] = locationData;
        await prefs.setString('CACHED_USER', jsonEncode(userMap));
      }

      return true;
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }

  // Get distance between two points in kilometers
  static double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert meters to kilometers
  }
}
