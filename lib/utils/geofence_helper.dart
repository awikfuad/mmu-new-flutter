import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Helper for GPS-based geofencing validation on the device side.
class GeofenceHelper {
  /// Calculate distance in meters between two GPS coordinates using Haversine formula.
  static double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Check if location permission is granted. If not, request it.
  /// Returns true if permission is granted.
  static Future<bool> ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }
    return true;
  }

  /// Check if location services are enabled on the device.
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get the current GPS position with accuracy.
  /// Returns null if permission denied or service disabled.
  static Future<GeoPosition?> getCurrentLocation() async {
    // Check services
    if (!await isLocationServiceEnabled()) return null;
    if (!await ensurePermission()) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return GeoPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate if current position is within the geofence.
  /// Returns a GeofenceResult with distance info.
  static GeofenceResult validate({
    required double currentLat,
    required double currentLng,
    required double schoolLat,
    required double schoolLng,
    required double radiusMeters,
  }) {
    final distance = haversineDistance(currentLat, currentLng, schoolLat, schoolLng);
    return GeofenceResult(
      distance: distance,
      isWithinRadius: distance <= radiusMeters,
    );
  }
}

/// Simple data class for GPS coordinates + accuracy.
class GeoPosition {
  final double latitude;
  final double longitude;
  final double accuracy;

  const GeoPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
  };
}

/// Result of a geofence validation.
class GeofenceResult {
  final double distance;
  final bool isWithinRadius;

  const GeofenceResult({
    required this.distance,
    required this.isWithinRadius,
  });
}
