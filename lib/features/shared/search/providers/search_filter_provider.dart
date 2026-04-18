import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/search_filter_model.dart';

class SearchFilterNotifier extends Notifier<SearchFilterModel> {
  final String _target;
  final String? _excludeId;

  SearchFilterNotifier(this._target, this._excludeId);

  @override
  SearchFilterModel build() =>
      SearchFilterModel(target: _target, excludeId: _excludeId);

  void setRadius(double km) => state = state.copyWith(radiusKm: km);

  void setMinRating(int rating) => state = state.copyWith(minRating: rating);

  void setAvailableOnly(bool value) =>
      state = state.copyWith(availableOnly: value);

  void setCategory(String? category) =>
      state = state.copyWith(category: category);

  void setVerifiedOnly(bool value) =>
      state = state.copyWith(verifiedOnly: value);

  void setLocation(double lat, double lng, String name) {
    state =
        state.copyWith(latitude: lat, longitude: lng, locationName: name);
  }

  /// Requests GPS and reverse-geocodes to a human-readable name.
  Future<void> useCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    String displayName =
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.subLocality, p.locality, p.country]
            .where((s) => s != null && s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) displayName = parts.join(', ');
      }
    } catch (_) {
      // Fallback to coordinate string
    }

    setLocation(pos.latitude, pos.longitude, displayName);
  }
}

/// Family provider keyed on (target, excludeId).
final searchFilterProvider = NotifierProvider.family
    .autoDispose<SearchFilterNotifier, SearchFilterModel,
        ({String target, String? excludeId})>(
  (args) => SearchFilterNotifier(args.target, args.excludeId),
);
