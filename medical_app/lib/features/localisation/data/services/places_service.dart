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
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Places API response status: ${data['status']}');

        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          print('Found ${results.length} places');

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

          return places;
        } else {
          print('Error fetching places: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }
          return [];
        }
      } else {
        print('Error fetching places: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception while fetching places: $e');
      return [];
    }
  }

  // Get place photo URL
  static String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }
}
