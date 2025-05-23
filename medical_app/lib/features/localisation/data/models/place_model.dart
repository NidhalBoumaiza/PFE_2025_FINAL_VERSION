import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/place_entity.dart';

class PlaceModel extends PlaceEntity {
  const PlaceModel({
    required String id,
    required String name,
    required String vicinity,
    required LatLng location,
    required PlaceType type,
    double rating = 0.0,
    bool isOpen = false,
    String? photoReference,
    String? phoneNumber,
    String? website,
    double distance = 0.0,
  }) : super(
         id: id,
         name: name,
         vicinity: vicinity,
         location: location,
         type: type,
         rating: rating,
         isOpen: isOpen,
         photoReference: photoReference,
         phoneNumber: phoneNumber,
         website: website,
         distance: distance,
       );

  factory PlaceModel.fromJson(
    Map<String, dynamic> json,
    PlaceType type, {
    double? userLat,
    double? userLng,
  }) {
    // Extract location data
    final location = json['geometry']['location'];
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;

    // Calculate distance if user location is provided
    double distance = 0.0;
    if (userLat != null && userLng != null) {
      // We'll calculate this in the service
      distance = 0.0;
    }

    // Extract opening hours if available
    bool isOpen = false;
    if (json['opening_hours'] != null) {
      isOpen = json['opening_hours']['open_now'] ?? false;
    }

    // Extract photo reference if available
    String? photoReference;
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      photoReference = json['photos'][0]['photo_reference'] as String?;
    }

    return PlaceModel(
      id: json['place_id'] as String,
      name: json['name'] as String,
      vicinity: json['vicinity'] as String,
      location: LatLng(lat, lng),
      type: type,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: isOpen,
      photoReference: photoReference,
      phoneNumber: json['formatted_phone_number'] as String?,
      website: json['website'] as String?,
      distance: distance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vicinity': vicinity,
      'location': {'lat': location.latitude, 'lng': location.longitude},
      'type': type.toString(),
      'rating': rating,
      'isOpen': isOpen,
      'photoReference': photoReference,
      'phoneNumber': phoneNumber,
      'website': website,
      'distance': distance,
    };
  }
}
