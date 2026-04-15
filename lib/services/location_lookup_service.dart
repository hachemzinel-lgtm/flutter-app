import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/services/location_permission_service.dart';

class LocationLookupResult {
  const LocationLookupResult({required this.geoPoint, required this.address});

  final GeoPoint geoPoint;
  final String address;
}

class LocationLookupService {
  static Future<LocationLookupResult?> detectCurrentLocation({
    required BuildContext context,
    Future<void> Function()? onRetry,
  }) async {
    print('--- [LOCATION] Requesting current location');
    final permissionResult =
        await LocationPermissionService.ensureLocationWhenInUsePermission();
    if (!permissionResult.isGranted) {
      if (context.mounted) {
        await LocationPermissionService.showPermissionFeedback(
          context,
          permissionResult,
          onRetry: onRetry,
        );
      }
      return null;
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
