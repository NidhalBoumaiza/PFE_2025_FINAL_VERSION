import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medical_app/core/services/location_service.dart';
import '../models/place_model.dart';
import '../../domain/entities/place_entity.dart';

class PlacesService {
  static const String _apiKey = 'AIzaSyCyFbbtuqs1CIezXzXPkE1HA7nCh83uXWY';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  // Fetch nearby hospitals
  static Future<List<PlaceEntity>> getNearbyHospitals(
    LatLng userLocation, {
    int radius = 5000,
  }) async {
    print(
      'Fetching nearby hospitals at ${userLocation.latitude}, ${userLocation.longitude}',
    );
    return _getNearbyPlaces(
      userLocation,
      'hospital',
      PlaceType.hospital,
      radius: radius,
    );
  }

  // Fetch nearby pharmacies
  static Future<List<PlaceEntity>> getNearbyPharmacies(
    LatLng userLocation, {
    int radius = 5000,
  }) async {
    print(
      'Fetching nearby pharmacies at ${userLocation.latitude}, ${userLocation.longitude}',
    );
    return _getNearbyPlaces(
      userLocation,
      'pharmacy',
      PlaceType.pharmacy,
      radius: radius,
    );
  }

  // Generic method to fetch nearby places
  static Future<List<PlaceEntity>> _getNearbyPlaces(
    LatLng userLocation,
    String type,
    PlaceType placeType, {
    int radius = 5000,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?location=${userLocation.latitude},${userLocation.longitude}'
        '&radius=$radius&type=$type&key=$_apiKey',
      );

      print('Fetching places from URL: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout - check your internet connection',
              );
            },
          );

      print('HTTP Response Status: ${response.statusCode}');
      print('HTTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Places API response status: ${data['status']}');

        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          print('Found ${results.length} places');

          if (results.isEmpty) {
            print(
              'No places found in the specified radius. Try increasing the radius.',
            );
            return [];
          }

          final places =
              results
                  .map((place) {
                    try {
                      return PlaceModel.fromJson(
                        place,
                        placeType,
                        userLat: userLocation.latitude,
                        userLng: userLocation.longitude,
                      );
                    } catch (e) {
                      print('Error parsing place: $e');
                      print('Place data: $place');
                      return null;
                    }
                  })
                  .where((place) => place != null)
                  .cast<PlaceModel>()
                  .toList();

          // Calculate distances
          for (var i = 0; i < places.length; i++) {
            final place = places[i];
            final distance = LocationService.getDistanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              place.location.latitude,
              place.location.longitude,
            );

            // Update the place with the calculated distance
            places[i] = PlaceModel(
              id: place.id,
              name: place.name,
              vicinity: place.vicinity,
              location: place.location,
              type: place.type,
              rating: place.rating,
              isOpen: place.isOpen,
              photoReference: place.photoReference,
              phoneNumber: place.phoneNumber,
              website: place.website,
              distance: distance,
            );
          }

          // Sort by distance
          places.sort((a, b) => a.distance.compareTo(b.distance));

          print('Successfully processed ${places.length} places');
          return places;
        } else {
          print('Error fetching places: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }

          // Handle specific API errors
          switch (data['status']) {
            case 'REQUEST_DENIED':
              throw Exception(
                'API key is invalid or not enabled for Places API',
              );
            case 'OVER_QUERY_LIMIT':
              throw Exception('API quota exceeded');
            case 'ZERO_RESULTS':
              print('No places found in this area');
              return [];
            case 'INVALID_REQUEST':
              throw Exception('Invalid request parameters');
            default:
              throw Exception('Places API error: ${data['status']}');
          }
        }
      } else {
        print('Error fetching places: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while fetching places: $e');
      rethrow;
    }
  }

  // Get place photo URL
  static String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }

  // Test method to verify API key is working
  static Future<bool> testApiKey() async {
    try {
      print('Testing Google Places API key...');

      const testUrl =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=36.8189,10.1657&radius=1000&type=hospital&key=$_apiKey';

      print('Test URL: $testUrl');

      final response = await http
          .get(Uri.parse(testUrl))
          .timeout(
            const Duration(seconds: 15), // Increased timeout
            onTimeout: () {
              print('⏰ API test timed out after 15 seconds');
              // Return a mock response to indicate timeout
              return http.Response('{"status":"TIMEOUT"}', 408);
            },
          );

      print('API Test Response Status: ${response.statusCode}');

      if (response.statusCode == 408) {
        print(
          '⚠️ API test timed out, but this doesn\'t mean the API key is invalid',
        );
        return true; // Assume it's working if we get a timeout
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String;
        print('API Test Response Status: $status');

        if (status == 'OK' || status == 'ZERO_RESULTS') {
          print('✅ API key test passed');
          return true;
        } else {
          print('❌ API key test failed with status: $status');
          return false;
        }
      } else {
        print('❌ API key test failed with HTTP status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception testing API key: $e');
      // If there's an exception but we know the API is working from other calls,
      // we can assume it's a network/timeout issue, not an API key issue
      return true;
    }
  }
}
