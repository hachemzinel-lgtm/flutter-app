import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_application_1/models/client_model.dart';
import 'package:flutter_application_1/models/marketplace_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/work_provider_model.dart';
import 'package:flutter_application_1/services/distance_service.dart';
import 'package:flutter_application_1/services/geocoding_service.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/models/discovery_models.dart';

class DiscoveryService {
  DiscoveryService({
    FirebaseFirestore? firestore,
    DistanceService? distanceService,
    GeocodingService? geocodingService,
    LocationService? locationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _distanceService = distanceService ?? DistanceService(),
       _geocodingService = geocodingService ?? GeocodingService(),
       _locationService = locationService ?? LocationService();

  final FirebaseFirestore _firestore;
  final DistanceService _distanceService;
  final GeocodingService _geocodingService;
  final LocationService _locationService;

  Future<DiscoverySearchLocation> resolveSearchLocation({
    required bool useCurrentLocation,
    required GeoPoint? savedLocation,
    required String? savedAddress,
    required String manualAddress,
  }) async {
    if (manualAddress.trim().isNotEmpty) {
      final location = await _geocodingService.geocodeAddress(
        manualAddress.trim(),
      );
      if (location == null) {
        throw Exception('We could not find that address on the map.');
      }
      return DiscoverySearchLocation(
        center: LatLng(location.latitude, location.longitude),
        label: manualAddress.trim(),
      );
    }

    if (useCurrentLocation) {
      final current = await _locationService.getCurrentLocation();
      if (current == null) {
        throw Exception(
          'Current location is unavailable. Use a saved or manual address.',
        );
      }
      return DiscoverySearchLocation(
        center: LatLng(current.latitude, current.longitude),
        label: 'Current location',
      );
    }

    if (savedLocation != null) {
      return DiscoverySearchLocation(
        center: LatLng(savedLocation.latitude, savedLocation.longitude),
        label: savedAddress?.isNotEmpty == true
            ? savedAddress!
            : 'Saved location',
      );
    }

    throw Exception('No search location is available yet.');
  }

  Future<List<DiscoverySearchResult>> search(
    DiscoverySearchRequest request,
  ) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('accountType', isEqualTo: request.type.firestoreValue)
        .where('isBanned', isEqualTo: false);

    if (request.type == DiscoverySearchType.workProviders) {
      query = query.where('verificationStatus', isEqualTo: 'approved');
    }

    if (request.category.isNotEmpty && request.category != 'Any') {
      query = query.where(
        request.type == DiscoverySearchType.workProviders
            ? 'profession'
            : 'category',
        isEqualTo: request.category,
      );
    }

    final snapshot = await query.limit(100).get();
    final results = <DiscoverySearchResult>[];

    for (final doc in snapshot.docs) {
      final user = _parseUser(doc);
      final geo = user.location;
      if (geo == null) {
        continue;
      }

      if (request.type == DiscoverySearchType.workProviders) {
        final provider = user as WorkProviderModel;
        if (request.availableOnly && !provider.isAvailableNow) {
          continue;
        }
        if (provider.rating < request.minimumRating) {
          continue;
        }
      } else if (user.rating < request.minimumRating) {
        continue;
      }

      final distanceKm = _distanceService.calculateDistance(
        request.location.center.latitude,
        request.location.center.longitude,
        geo.latitude,
        geo.longitude,
      );

      if (distanceKm > request.radiusKm) {
        continue;
      }

      results.add(DiscoverySearchResult(user: user, distanceKm: distanceKm));
    }

    results.sort((left, right) {
      final ratingCompare = right.user.rating.compareTo(left.user.rating);
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      return left.distanceKm.compareTo(right.distanceKm);
    });

    return results;
  }

  Future<List<DiscoverySearchResult>> topRatedProviders({
    required GeoPoint? savedLocation,
    required String? savedAddress,
  }) async {
    if (savedLocation == null) {
      return const [];
    }

    final request = DiscoverySearchRequest(
      type: DiscoverySearchType.workProviders,
      category: 'Any',
      radiusKm: 20,
      minimumRating: 0,
      availableOnly: false,
      location: DiscoverySearchLocation(
        center: LatLng(savedLocation.latitude, savedLocation.longitude),
        label: savedAddress?.isNotEmpty == true
            ? savedAddress!
            : 'Saved location',
      ),
    );

    return search(request);
  }

  Stream<List<DiscoverySearchResult>> streamProviders({
    required DiscoverySearchType type,
    String? category,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('accountType', isEqualTo: type.firestoreValue)
        .where('isBanned', isEqualTo: false);

    if (type == DiscoverySearchType.workProviders) {
      query = query.where('verificationStatus', isEqualTo: 'approved');
    }

    if (category != null && category.isNotEmpty && category != 'Any') {
      query = query.where(
        type == DiscoverySearchType.workProviders ? 'profession' : 'category',
        isEqualTo: category,
      );
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = _parseUser(doc);
        return DiscoverySearchResult(user: user, distanceKm: 0);
      }).toList();
    });
  }

  UserModel _parseUser(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final type = UserModel.parseUserType(
      data['accountType'] as String? ?? 'client',
    );
    switch (type) {
      case UserType.client:
        return ClientModel.fromMap(doc.id, data);
      case UserType.workProvider:
        return WorkProviderModel.fromMap(doc.id, data);
      case UserType.marketplace:
        return MarketplaceModel.fromMap(doc.id, data);
    }
  }
}
