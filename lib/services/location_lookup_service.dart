import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationLookupResult {
  const LocationLookupResult({required this.geoPoint, required this.address});

  final GeoPoint geoPoint;
  final String address;
}

class LocationLookupService {
  static Future<LocationLookupResult> detectCurrentLocation() async {
    print('--- [LOCATION] Requesting current location');
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to continue.');
    }

    final position = await Geolocator.getCurrentPosition();
    final address = await _reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return LocationLookupResult(
      geoPoint: GeoPoint(position.latitude, position.longitude),
      address: address,
    );
  }

  static Future<String> _reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    print('--- [LOCATION] Reverse geocoding with Nominatim');
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'zoom': '18',
      'addressdetails': '1',
    });

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'NearWork/1.0 (Flutter app reverse geocoding)',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to resolve your address right now.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final displayName = payload['display_name']?.toString();
    if (displayName == null || displayName.trim().isEmpty) {
      throw Exception('Address lookup returned an empty result.');
    }
    return displayName;
  }
}
