import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/services/location_permission_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Gets the user's current GPS location. Requests permissions if needed.
  Future<Position?> getCurrentLocation({
    BuildContext? context,
    Future<void> Function()? onRetry,
  }) async {
    try {
      final permissionResult =
          await LocationPermissionService.ensureLocationWhenInUsePermission();
      if (!permissionResult.isGranted) {
        debugPrint(permissionResult.message);
        if (context != null && context.mounted) {
          await LocationPermissionService.showPermissionFeedback(
            context,
            permissionResult,
            onRetry: onRetry,
          );
        }
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Streams location updates.
  Stream<Position> streamLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    );
  }
}
