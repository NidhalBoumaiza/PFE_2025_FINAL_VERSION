import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medical_app/core/services/location_service.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/widgets/location_activation_screen.dart';
import 'package:medical_app/features/localisation/data/services/places_service.dart';
import 'package:medical_app/features/localisation/domain/entities/place_entity.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmaciePage extends StatefulWidget {
  final PlaceType initialType;

  const PharmaciePage({super.key, this.initialType = PlaceType.hospital});

  @override
  State<PharmaciePage> createState() => _PharmaciePageState();
}

class _PharmaciePageState extends State<PharmaciePage> {
  final Completer<GoogleMapController> _controller = Completer();
  late PlaceType _currentType;
  bool _isLoading = true;
  bool _isLoadingPlaces = false;
  LatLng? _currentPosition;
  List<PlaceEntity> _places = [];
  Set<Marker> _markers = {};
  PlaceEntity? _selectedPlace;
  final double _defaultZoom = 14.0;

  // Default location (Tunis) to use when user location isn't available
  final LatLng _defaultLocation = const LatLng(36.8189, 10.1657);

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _testApiKey(); // Test API key first
    _checkLocationPermission();
  }

  Future<void> _testApiKey() async {
    try {
      print('🔍 Testing Google Places API key...');

      // Test both Maps and Places API
      final isPlacesWorking = await PlacesService.testApiKey();
      print('Places API test result: $isPlacesWorking');

      if (!isPlacesWorking) {
        print(
          '⚠️ Places API key test failed - but this might be a network issue',
        );
        // Don't show error to user since the actual API calls might still work
      } else {
        print('✅ Places API key test passed');
      }

      // Test Maps API by trying to load a simple map
      print('🗺️ Testing Google Maps API...');
    } catch (e) {
      print('❌ Error testing API key: $e');
      // Don't show error to user since this is just a test
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      print('Checking location permission...');
      final serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services not enabled');
        _showLocationActivationScreen();
        return;
      }

      final permission = await Geolocator.checkPermission();
      print('Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        print('Location permission denied, requesting permission...');
        _showLocationActivationScreen();
      } else if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        showErrorSnackBar(context, 'Autorisation de localisation refusée');
        setState(() {
          _isLoading = false;
          // Use default location
          _currentPosition = _defaultLocation;
          _fetchNearbyPlaces();
        });
      } else {
        print(
          'Location permission already granted, getting current location...',
        );
        _getCurrentLocation();
      }
    } catch (e) {
      print('Error checking location permission: $e');
      setState(() {
        _isLoading = false;
        // Use default location
        _currentPosition = _defaultLocation;
        _fetchNearbyPlaces();
      });
    }
  }

  void _showLocationActivationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationActivationScreen(
              onLocationEnabled: () {
                _getCurrentLocation();
              },
            ),
      ),
    ).then((enabled) {
      if (enabled != true) {
        // User denied or closed the screen without enabling
        setState(() {
          _isLoading = false;
          // Use default location
          _currentPosition = _defaultLocation;
          _fetchNearbyPlaces();
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('Getting current location...');
      final position = await LocationService.getCurrentPosition();

      if (position != null) {
        print('Position received: ${position.latitude}, ${position.longitude}');

        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _isLoading = false;
          });
          _fetchNearbyPlaces();
        }
      } else {
        print('Could not get current position, using default location');
        if (mounted) {
          setState(() {
            _currentPosition = _defaultLocation;
            _isLoading = false;
          });
          showErrorSnackBar(context, 'Impossible d\'obtenir la localisation');
          _fetchNearbyPlaces();
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        setState(() {
          _currentPosition = _defaultLocation;
          _isLoading = false;
        });
        showErrorSnackBar(context, 'Impossible d\'obtenir la localisation');
        _fetchNearbyPlaces();
      }
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition == null) {
      print('Cannot fetch places: current position is null');
      return;
    }

    setState(() {
      _isLoadingPlaces = true;
      _selectedPlace = null;
    });

    try {
      print(
        'Fetching nearby ${_currentType == PlaceType.hospital ? "hospitals" : "pharmacies"}...',
      );
      print(
        'Current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );

      List<PlaceEntity> places;
      if (_currentType == PlaceType.hospital) {
        places = await PlacesService.getNearbyHospitals(_currentPosition!);
      } else {
        places = await PlacesService.getNearbyPharmacies(_currentPosition!);
      }

      print('Received ${places.length} places');

      // Debug: Print first few places
      for (int i = 0; i < places.length && i < 3; i++) {
        print('Place $i: ${places[i].name} at ${places[i].location}');
      }

      if (mounted) {
        setState(() {
          _places = places;
          _isLoadingPlaces = false;
        });

        _updateMarkers();

        // If we have places, animate to show them
        if (places.isNotEmpty && _currentPosition != null) {
          _animateToShowAllPlaces();
        }
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
        });
        showErrorSnackBar(context, 'Erreur lors de la récupération des lieux');
      }
    }
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;

    Set<Marker> markers = {};

    // Add user marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'Votre position'),
      ),
    );

    // Add place markers
    for (var place in _places) {
      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: place.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.type == PlaceType.hospital
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: place.name, snippet: place.vicinity),
          onTap: () {
            setState(() {
              _selectedPlace = place;
            });
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _animateToPosition(LatLng position) async {
    try {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(position, _defaultZoom),
      );
    } catch (e) {
      print('Error animating to position: $e');
    }
  }

  Future<void> _animateToShowAllPlaces() async {
    try {
      if (_places.isEmpty || _currentPosition == null) return;

      final GoogleMapController controller = await _controller.future;

      // Calculate bounds to show all places and user location
      double minLat = _currentPosition!.latitude;
      double maxLat = _currentPosition!.latitude;
      double minLng = _currentPosition!.longitude;
      double maxLng = _currentPosition!.longitude;

      for (var place in _places) {
        minLat =
            minLat < place.location.latitude ? minLat : place.location.latitude;
        maxLat =
            maxLat > place.location.latitude ? maxLat : place.location.latitude;
        minLng =
            minLng < place.location.longitude
                ? minLng
                : place.location.longitude;
        maxLng =
            maxLng > place.location.longitude
                ? maxLng
                : place.location.longitude;
      }

      // Add some padding
      final padding = 0.01;
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding
        ),
      );
    } catch (e) {
      print('Error animating to show all places: $e');
      // Fallback to showing current position
      _animateToPosition(_currentPosition!);
    }
  }

  Future<void> _launchMapsUrl(LatLng destination) async {
    if (_currentPosition == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
      '&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
    );

    try {
      print('Launching maps URL: $url');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        showErrorSnackBar(context, 'Impossible d\'ouvrir Google Maps');
      }
    } catch (e) {
      print('Error launching maps: $e');
      showErrorSnackBar(context, 'Impossible d\'ouvrir Google Maps');
    }
  }

  Widget _buildPlacesList() {
    if (_isLoadingPlaces) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    if (_places.isEmpty) {
      return Center(
        child: Text(
          'Aucun lieu trouvé',
          style: GoogleFonts.raleway(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            title: Text(
              place.name,
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text(
                  place.vicinity,
                  style: GoogleFonts.raleway(fontSize: 14.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${place.distance.toStringAsFixed(1)} km',
                  style: GoogleFonts.raleway(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.directions, color: AppColors.primaryColor),
              onPressed: () => _launchMapsUrl(place.location),
            ),
            onTap: () {
              setState(() {
                _selectedPlace = place;
              });
              _animateToPosition(place.location);
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedPlaceCard() {
    if (_selectedPlace == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedPlace!.name,
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20.sp),
                onPressed: () {
                  setState(() {
                    _selectedPlace = null;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _selectedPlace!.vicinity,
            style: GoogleFonts.raleway(fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.location_on, size: 16.sp, color: Colors.grey[600]),
              SizedBox(width: 4.w),
              Text(
                '${_selectedPlace!.distance.toStringAsFixed(1)} km',
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              if (_selectedPlace!.rating > 0) ...[
                SizedBox(width: 16.w),
                Icon(Icons.star, size: 16.sp, color: Colors.amber),
                SizedBox(width: 4.w),
                Text(
                  _selectedPlace!.rating.toStringAsFixed(1),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.directions),
              label: Text('Obtenir l\'itinéraire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () => _launchMapsUrl(_selectedPlace!.location),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🏗️ Building PharmaciePage - isLoading: $_isLoading, currentPosition: $_currentPosition, places: ${_places.length}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentType == PlaceType.hospital ? 'Hôpitaux' : 'Pharmacies',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed:
                _isLoading || _isLoadingPlaces ? null : _fetchNearbyPlaces,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Obtention de la localisation',
                      style: GoogleFonts.raleway(fontSize: 16.sp),
                    ),
                  ],
                ),
              )
              : _currentPosition == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text(
                      'Location not available',
                      style: GoogleFonts.raleway(fontSize: 16.sp),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: _checkLocationPermission,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  // Google Map
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition ?? _defaultLocation,
                        zoom: _defaultZoom,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        print('🗺️ GoogleMap created successfully');
                        print(
                          'Map position: ${_currentPosition ?? _defaultLocation}',
                        );
                        print('Markers count: ${_markers.length}');

                        if (!_controller.isCompleted) {
                          _controller.complete(controller);
                          print('✅ GoogleMap controller completed');

                          // Fetch places after map is ready if we haven't already
                          if (_places.isEmpty &&
                              _currentPosition != null &&
                              !_isLoadingPlaces) {
                            print('🔄 Map ready, fetching places...');
                            _fetchNearbyPlaces();
                          }
                        }
                      },
                      onCameraMove: (CameraPosition position) {
                        // Optional: Add camera move handling
                        print('📷 Camera moved to: ${position.target}');
                      },
                      onTap: (LatLng position) {
                        print('👆 Map tapped at: $position');
                        // Clear selected place when tapping on map
                        if (_selectedPlace != null) {
                          setState(() {
                            _selectedPlace = null;
                          });
                        }
                      },
                      // Add error handling
                      onCameraIdle: () {
                        print('📷 Camera idle');
                      },
                      onCameraMoveStarted: () {
                        print('📷 Camera move started');
                      },
                    ),
                  ),

                  // Toggle buttons
                  Positioned(
                    top: 16.h,
                    left: 16.w,
                    right: 16.w,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_currentType != PlaceType.hospital) {
                                  setState(() {
                                    _currentType = PlaceType.hospital;
                                  });
                                  _fetchNearbyPlaces();
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color:
                                      _currentType == PlaceType.hospital
                                          ? AppColors.primaryColor
                                          : Colors.white,
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(8.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_hospital,
                                      color:
                                          _currentType == PlaceType.hospital
                                              ? Colors.white
                                              : Colors.grey[600],
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Hôpitaux',
                                      style: GoogleFonts.raleway(
                                        color:
                                            _currentType == PlaceType.hospital
                                                ? Colors.white
                                                : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_currentType != PlaceType.pharmacy) {
                                  setState(() {
                                    _currentType = PlaceType.pharmacy;
                                  });
                                  _fetchNearbyPlaces();
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color:
                                      _currentType == PlaceType.pharmacy
                                          ? AppColors.primaryColor
                                          : Colors.white,
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(8.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_pharmacy,
                                      color:
                                          _currentType == PlaceType.pharmacy
                                              ? Colors.white
                                              : Colors.grey[600],
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Pharmacies',
                                      style: GoogleFonts.raleway(
                                        color:
                                            _currentType == PlaceType.pharmacy
                                                ? Colors.white
                                                : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // My location button
                  Positioned(
                    bottom: _selectedPlace != null ? 200.h : 16.h,
                    right: 16.w,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryColor,
                      onPressed: () {
                        if (_currentPosition != null) {
                          _animateToPosition(_currentPosition!);
                        } else {
                          _getCurrentLocation();
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),

                  // List button
                  Positioned(
                    bottom: _selectedPlace != null ? 200.h : 16.h,
                    left: 16.w,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryColor,
                      onPressed: () {
                        _showPlacesBottomSheet();
                      },
                      child: const Icon(Icons.list),
                    ),
                  ),

                  // Selected place info
                  if (_selectedPlace != null)
                    Positioned(
                      bottom: 16.h,
                      left: 16.w,
                      right: 16.w,
                      child: _buildSelectedPlaceCard(),
                    ),

                  // Loading indicator for places
                  if (_isLoadingPlaces)
                    Positioned(
                      top: 80.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Chargement des lieux',
                                style: GoogleFonts.raleway(fontSize: 14.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  void _showPlacesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.only(top: 16.h),
          child: Column(
            children: [
              Container(
                width: 40.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Icon(
                      _currentType == PlaceType.hospital
                          ? Icons.local_hospital
                          : Icons.local_pharmacy,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _currentType == PlaceType.hospital
                          ? 'Hôpitaux à proximité'
                          : 'Pharmacies à proximité',
                      style: GoogleFonts.raleway(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_places.length} ' + 'trouvé(s)',
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Divider(),
              Expanded(child: _buildPlacesList()),
            ],
          ),
        );
      },
    );
  }
}
