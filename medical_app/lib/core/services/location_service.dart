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
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final prefs = await SharedPreferences.getInstance();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await prefs.setBool(LOCATION_PERMISSION_KEY, true);
    } else {
      await prefs.setBool(LOCATION_PERMISSION_KEY, false);
    }

    return permission;
  }

  // Get current position - improved implementation
  static Future<Position?> getCurrentPosition({int timeoutSeconds = 10}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try to open location settings
        await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission checkPermission = await Geolocator.checkPermission();
      if (checkPermission == LocationPermission.denied) {
        LocationPermission requestPermission =
            await Geolocator.requestPermission();
        if (requestPermission != LocationPermission.whileInUse &&
            requestPermission != LocationPermission.always) {
          return null;
        }
      }

      // Always try to get the most accurate position possible
      try {
        // First try with high accuracy and timeout
        var position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: timeoutSeconds),
        );

        print(
          'Got accurate position: ${position.latitude}, ${position.longitude}',
        );
        return position;
      } catch (timeoutError) {
        print('High accuracy position timed out, trying with lower accuracy');
        // If high accuracy times out, try with lower accuracy
        var position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        );

        print(
          'Got medium accuracy position: ${position.latitude}, ${position.longitude}',
        );
        return position;
      }
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Update user location in Firestore
  static Future<bool> updateUserLocation(String userId, String userType) async {
    try {
      // Get current position using our improved method
      final position = await getCurrentPosition();
      if (position == null) {
        print('Could not get current position');
        return false;
      }

      // Format location data for Firestore using GeoJSON format [longitude, latitude]
      final locationData = {
        'type': 'Point',
        'coordinates': [position.longitude, position.latitude],
      };

      // Add timestamp separately to avoid serialization issues
      final Map<String, dynamic> updateData = {
        'location': locationData,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      };

      // Determine collection based on user type
      final collection = userType == 'patient' ? 'patients' : 'medecins';

      // Update Firestore
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .update(updateData);

      // Also update in shared preferences for cached user
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('CACHED_USER');
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        userMap['location'] = locationData;
        await prefs.setString('CACHED_USER', jsonEncode(userMap));
      }

      print(
        'Location updated successfully: ${position.latitude}, ${position.longitude}',
      );
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
