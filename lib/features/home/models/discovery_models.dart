import 'package:latlong2/latlong.dart';

import '../../../core/models/user_model.dart';

enum DiscoverySearchType {
  workProviders,
  marketplaces;

  String get firestoreValue {
    switch (this) {
      case DiscoverySearchType.workProviders:
        return 'workProvider';
      case DiscoverySearchType.marketplaces:
        return 'marketplace';
    }
  }

  String get queryValue {
    switch (this) {
      case DiscoverySearchType.workProviders:
        return 'provider';
      case DiscoverySearchType.marketplaces:
        return 'marketplace';
    }
  }

  static DiscoverySearchType fromQuery(String? value) {
    return value == 'marketplace'
        ? DiscoverySearchType.marketplaces
        : DiscoverySearchType.workProviders;
  }
}

class DiscoverySearchLocation {
  const DiscoverySearchLocation({required this.center, required this.label});

  final LatLng center;
  final String label;

  @override
  bool operator ==(Object other) {
    return other is DiscoverySearchLocation &&
        other.center.latitude == center.latitude &&
        other.center.longitude == center.longitude &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(center.latitude, center.longitude, label);
}

class DiscoverySearchRequest {
  const DiscoverySearchRequest({
    required this.type,
    required this.category,
    required this.radiusKm,
    required this.minimumRating,
    required this.availableOnly,
    required this.location,
  });

  final DiscoverySearchType type;
  final String category;
  final double radiusKm;
  final double minimumRating;
  final bool availableOnly;
  final DiscoverySearchLocation location;

  @override
  bool operator ==(Object other) {
    return other is DiscoverySearchRequest &&
        other.type == type &&
        other.category == category &&
        other.radiusKm == radiusKm &&
        other.minimumRating == minimumRating &&
        other.availableOnly == availableOnly &&
        other.location == location;
  }

  @override
  int get hashCode => Object.hash(
    type,
    category,
    radiusKm,
    minimumRating,
    availableOnly,
    location,
  );
}

class DiscoverySearchResult {
  const DiscoverySearchResult({required this.user, required this.distanceKm});

  final UserModel user;
  final double distanceKm;

  bool get isVerified {
    final data = user.toJson();
    return data['verificationStatus'] == 'approved' ||
        data['isVerified'] == true;
  }
}
