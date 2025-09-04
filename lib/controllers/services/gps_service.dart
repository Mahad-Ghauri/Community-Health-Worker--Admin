// ignore_for_file: deprecated_member_use

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// GPS Service - Handles location capture for visits and patient registration
/// Used by: Register New Patient (10), New Visit (14), and all audit logging
/// Auto-captures GPS coordinates as proof of field work
class GPSService {
  static const double _desiredAccuracy = 10.0; // meters

  /// Get current GPS location with proper permissions
  /// Used by: All screens that require location proof
  Future<Map<String, double>> getCurrentLocation() async {
    try {
      // Check and request location permissions
      final permission = await _checkLocationPermission();
      if (!permission) {
        throw Exception('Location permission denied');
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toDouble(),
      };

    } catch (e) {
      // Return approximate location or throw error based on context
      throw Exception('Failed to get GPS location: $e');
    }
  }

  /// Get location with retry mechanism for critical operations
  /// Used by: Patient registration and visit logging
  Future<Map<String, double>> getCurrentLocationWithRetry({
    int maxRetries = 3,
    int delaySeconds = 5,
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await getCurrentLocation();
      } catch (e) {
        lastException = Exception('Attempt $attempt failed: $e');
        
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }
    
    throw lastException ?? Exception('All location attempts failed');
  }

  /// Get cached/last known location if GPS fails
  /// Used as fallback when real-time GPS is not available
  Future<Map<String, double>?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return {
          'lat': position.latitude,
          'lng': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.millisecondsSinceEpoch.toDouble(),
          'is_cached': 1.0, // Flag to indicate this is cached data
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if location permissions are granted
  /// Used by: First Time Setup Screen (Screen 5)
  Future<bool> _checkLocationPermission() async {
    try {
      // Check current permission status
      var status = await Permission.location.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        // Request permission
        status = await Permission.location.request();
        return status.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        // User has permanently denied permission
        return false;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Request location permissions during app setup
  /// Used by: First Time Setup Screen (Screen 5)
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check if high accuracy location is available
  /// Used to determine GPS quality for critical operations
  Future<bool> isHighAccuracyAvailable() async {
    try {
      final permission = await _checkLocationPermission();
      if (!permission) return false;
      
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      
      // Try to get a position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Consider high accuracy if within desired range
      return position.accuracy <= _desiredAccuracy;
    } catch (e) {
      return false;
    }
  }

  /// Calculate distance between two GPS points
  /// Used for: Visit validation (ensure CHW is at patient location)
  double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Validate if CHW is near patient location for visit
  /// Used by: New Visit Screen (Screen 14) to ensure genuine visits
  Future<bool> validateVisitLocation({
    required Map<String, double> patientLocation,
    double allowedRadius = 100.0, // meters
  }) async {
    try {
      final currentLocation = await getCurrentLocation();
      
      final distance = calculateDistance(
        lat1: currentLocation['lat']!,
        lng1: currentLocation['lng']!,
        lat2: patientLocation['lat']!,
        lng2: patientLocation['lng']!,
      );
      
      return distance <= allowedRadius;
    } catch (e) {
      // Allow visit if GPS validation fails (don't block CHW work)
      return true;
    }
  }

  /// Get location accuracy description for UI display
  /// Used to show GPS quality to CHWs
  String getAccuracyDescription(double accuracy) {
    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 10) return 'Good';
    if (accuracy <= 20) return 'Fair';
    if (accuracy <= 50) return 'Poor';
    return 'Very Poor';
  }

  /// Start location tracking for background visits
  /// Used for continuous tracking during field work
  Stream<Position> startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );
    
    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }

  /// Check GPS settings and provide user guidance
  /// Used by: App Settings Screen (Screen 29) for GPS configuration
  Future<Map<String, dynamic>> getGPSStatus() async {
    try {
      final permission = await Permission.location.status;
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final highAccuracy = await isHighAccuracyAvailable();
      
      return {
        'permission_granted': permission.isGranted,
        'service_enabled': serviceEnabled,
        'high_accuracy': highAccuracy,
        'permission_status': permission.toString(),
        'recommendations': _getGPSRecommendations(
          permission.isGranted,
          serviceEnabled,
          highAccuracy,
        ),
      };
    } catch (e) {
      return {
        'permission_granted': false,
        'service_enabled': false,
        'high_accuracy': false,
        'error': e.toString(),
      };
    }
  }

  /// Get recommendations for improving GPS accuracy
  List<String> _getGPSRecommendations(
    bool permissionGranted,
    bool serviceEnabled,
    bool highAccuracy,
  ) {
    final recommendations = <String>[];
    
    if (!permissionGranted) {
      recommendations.add('Grant location permission in app settings');
    }
    
    if (!serviceEnabled) {
      recommendations.add('Enable location services in device settings');
    }
    
    if (!highAccuracy) {
      recommendations.addAll([
        'Move to an open area away from buildings',
        'Wait a few moments for GPS to stabilize',
        'Ensure device has clear view of the sky',
      ]);
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('GPS is working optimally');
    }
    
    return recommendations;
  }

  /// Format GPS coordinates for display
  /// Used in UI to show location information to CHWs
  String formatCoordinates(Map<String, double> location) {
    final lat = location['lat']?.toStringAsFixed(6) ?? '0.000000';
    final lng = location['lng']?.toStringAsFixed(6) ?? '0.000000';
    final accuracy = location['accuracy']?.toStringAsFixed(1) ?? '0.0';
    
    return 'Lat: $lat, Lng: $lng (±${accuracy}m)';
  }

  /// Get address from coordinates (basic implementation)
  /// Used to display human-readable addresses
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    // Basic implementation without geocoding package
    // In production, you would use geocoding package
    return formatCoordinates({
      'lat': latitude,
      'lng': longitude,
    });
  }
}
