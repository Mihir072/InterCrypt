import 'dart:math' show cos, sqrt, asin;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service.dart';

class LocationVerificationService {
  final LocationService _locationService;

  LocationVerificationService(this._locationService);

  /// Calculate distance between two points using the Haversine formula (in meters)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2 * R; R = 6371 km = 6371000 m
  }

  /// Check if the user is currently within the allowed radius of the restricted location
  Future<VerificationResult> isUserWithinAllowedLocation({
    required double targetLat,
    required double targetLon,
    required double allowedRadius,
  }) async {
    final position = await _locationService.getCurrentLocation();
    
    if (position == null) {
      return VerificationResult(
        isAllowed: false,
        error: 'Location access is required to view location-protected content.',
        isPermissionDenied: true,
      );
    }

    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      targetLat,
      targetLon,
    );

    return VerificationResult(
      isAllowed: distance <= allowedRadius,
      distance: distance,
      currentLat: position.latitude,
      currentLon: position.longitude,
    );
  }
}

class VerificationResult {
  final bool isAllowed;
  final double? distance;
  final double? currentLat;
  final double? currentLon;
  final String? error;
  final bool isPermissionDenied;

  VerificationResult({
    required this.isAllowed,
    this.distance,
    this.currentLat,
    this.currentLon,
    this.error,
    this.isPermissionDenied = false,
  });
}

final locationVerificationServiceProvider = Provider<LocationVerificationService>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationVerificationService(locationService);
});
