import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();
  
  // Current location
  Position? _currentPosition;
  
  // Status
  bool _isLocationEnabled = false;
  bool _hasPermission = false;
  
  bool get isLocationEnabled => _isLocationEnabled;
  bool get hasPermission => _hasPermission;
  Position? get currentPosition => _currentPosition;
  
  /// Check if location services are enabled
  Future<bool> checkLocationEnabled() async {
    _isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    return _isLocationEnabled;
  }
  
  /// Check and request location permission
  Future<bool> checkAndRequestPermission() async {
    PermissionStatus status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    _hasPermission = status.isGranted;
    return _hasPermission;
  }
  
  /// Get current location with high accuracy
  Future<Position?> getCurrentLocation() async {
    try {
      // First check if location is enabled
      bool locationEnabled = await checkLocationEnabled();
      if (!locationEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }
      
      // Check permission
      bool hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied. Please grant permission.');
      }
      
      // Get location with high accuracy
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
      
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
  
  /// Get location as Map (lat, long)
  Future<Map<String, double>> getLocationMap() async {
    Position? position = await getCurrentLocation();
    
    if (position != null) {
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    }
    
    // Return default coordinates if location fails (testing purposes)
    // You can remove this fallback in production
    return {
      'latitude': 28.6139,  // Default: New Delhi
      'longitude': 77.2090,
    };
  }
  
  /// Check if user is at a valid location (optional - for fraud prevention)
  Future<bool> isValidLocation() async {
    Map<String, double> location = await getLocationMap();
    double lat = location['latitude']!;
    double lng = location['longitude']!;
    
    // India bounds: 8°4'N to 37°6'N latitude, 68°7'E to 97°25'E longitude
    if (lat >= 8.0 && lat <= 37.1 && lng >= 68.0 && lng <= 97.5) {
      return true;
    }
    return false;
  }
  
  /// Show location dialog if location is disabled
  Future<bool> showLocationDialog(BuildContext context) async {
    bool locationEnabled = await checkLocationEnabled();
    bool hasPermission = await checkAndRequestPermission();
    
    if (!locationEnabled || !hasPermission) {
      if (context.mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text(
              'Location Required',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'AEPS transactions require your location. Please enable GPS and location permission to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext, true);
                  if (!locationEnabled) {
                    await Geolocator.openLocationSettings();
                  } else if (!hasPermission) {
                    await openAppSettings();
                  }
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        );
        return result ?? false;
      }
      return false;
    }
    return true;
  }
}