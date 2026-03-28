import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Converts a string address into lat/lng coordinates.
  Future<Location?> geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
    } catch (e) {
      debugPrint('Error geocoding address "$address": $e');
    }
    return null;
  }

  /// Converts lat/lng coordinates into a human-readable address.
  Future<Placemark?> reverseGeocode(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
    } catch (e) {
      debugPrint('Error reverse geocoding ($latitude, $longitude): $e');
    }
    return null;
  }
}
