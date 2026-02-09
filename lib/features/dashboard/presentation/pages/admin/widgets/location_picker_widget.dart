import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cementdeliverytracker/core/services/geocoding_cache_service.dart';
import 'package:cementdeliverytracker/core/services/api_usage_monitoring_service.dart';
import 'package:cementdeliverytracker/core/utils/debouncer.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPickerWidget extends StatefulWidget {
  final LocationPickerResult? initialLocation;
  final Function(LocationPickerResult) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  LatLng _selectedLocation = const LatLng(28.7041, 77.1025); // Default: Delhi
  String _selectedAddress = '';
  Set<Marker> _markers = {};
  bool _isLoading = false;

  // Cache and monitoring services
  final _geocodingCache = GeocodingCacheService();
  final _apiMonitor = APIUsageMonitoringService();

  // Debouncer for map tap events (500ms delay to avoid rapid API calls)
  late final Debouncer _addressDebouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _selectedAddress = widget.initialLocation!.address;
      _addMarker();
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _addressDebouncer.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      await _getAddressFromCoordinates();
      // Use cached geocoding service to reduce API calls
      final placemarks = await _geocodingCache.getPlacemarksFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      // Track API usage (cache hit/miss handled in service)
      _apiMonitor.recordGeocodingCall(
        coordinates:
            '${_selectedLocation.latitude.toStringAsFixed(6)},${_selectedLocation.longitude.toStringAsFixed(6)}',
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            final parts =
                [
                      place.street,
                      place.subLocality,
                      place.locality,
                      place.administrativeArea,
                      place.postalCode,
                      place.country,
                    ]
                    .whereType<String>()
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty);
            _selectedAddress = parts.join(', ');
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = 'Error fetching address';
        });
      }
    }
  }

  void _addMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _selectedAddress.isEmpty
                ? 'Loading address...'
                : _selectedAddress,
          ),
        ),
      };
    });
  }

  Future<void> _getAddressFromCoordinates() async {
    try {
      // Use cached geocoding service to reduce API calls
      final placemarks = await _geocodingCache.getPlacemarksFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      // Track API usage (cache hit/miss handled in service)
      _apiMonitor.recordGeocodingCall(
        coordinates:
            '${_selectedLocation.latitude.toStringAsFixed(6)},${_selectedLocation.longitude.toStringAsFixed(6)}',
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
          final parts =
              [
                    place.street,
                    place.subLocality,
                    place.locality,
                    place.administrativeArea,
                    place.postalCode,
                    place.country,
                  ]
                  .whereType<String>()
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty);
          _selectedAddress = parts.join(', ');
        });
        _addMarker();
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = 'Error fetching address';
        });
        _addMarker();
      }
    }
  }

  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _selectedAddress = 'Loading address...';
    });
    _addMarker();

    // Debounce address lookup to avoid rapid API calls when user is dragging/tapping rapidly
    _addressDebouncer.call(() {
      if (mounted) {
        _getAddressFromCoordinates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Pick Location'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      final result = LocationPickerResult(
                        latitude: _selectedLocation.latitude,
                        longitude: _selectedLocation.longitude,
                        address: _selectedAddress,
                      );
                      widget.onLocationSelected(result);
                      Navigator.pop(context, result);
                    },
              icon: const Icon(Icons.check),
              label: const Text('Select'),
            ),
          ],
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 15,
              ),
              markers: _markers,
              onTap: _onMapTap,
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress.isEmpty
                          ? 'Fetching address...'
                          : _selectedAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _getCurrentLocation,
          tooltip: 'Use current location',
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}
