import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PlaceType { hospital, pharmacy }

class PlaceEntity extends Equatable {
  final String id;
  final String name;
  final String vicinity;
  final double rating;
  final LatLng location;
  final PlaceType type;
  final bool isOpen;
  final String? photoReference;
  final String? phoneNumber;
  final String? website;
  final double distance; // distance in km from user

  const PlaceEntity({
    required this.id,
    required this.name,
    required this.vicinity,
    required this.location,
    required this.type,
    this.rating = 0.0,
    this.isOpen = false,
    this.photoReference,
    this.phoneNumber,
    this.website,
    this.distance = 0.0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    vicinity,
    location,
    type,
    rating,
    isOpen,
    photoReference,
    phoneNumber,
    website,
    distance,
  ];
}
