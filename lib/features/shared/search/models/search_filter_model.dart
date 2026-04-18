class SearchFilterModel {
  final String target; // 'work_provider' or 'marketplace'
  final double latitude;
  final double longitude;
  final String locationName;
  final double radiusKm;
  final int minRating; // 0 = any
  final bool availableOnly;
  final String? category; // null or 'Any' = no filter
  final bool verifiedOnly; // WP only
  final String? excludeId; // MP: exclude own profile

  const SearchFilterModel({
    required this.target,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.locationName = '',
    this.radiusKm = 10.0,
    this.minRating = 0,
    this.availableOnly = false,
    this.category,
    this.verifiedOnly = false,
    this.excludeId,
  });

  SearchFilterModel copyWith({
    String? target,
    double? latitude,
    double? longitude,
    String? locationName,
    double? radiusKm,
    int? minRating,
    bool? availableOnly,
    Object? category = _sentinel,
    bool? verifiedOnly,
    Object? excludeId = _sentinel,
  }) {
    return SearchFilterModel(
      target: target ?? this.target,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      radiusKm: radiusKm ?? this.radiusKm,
      minRating: minRating ?? this.minRating,
      availableOnly: availableOnly ?? this.availableOnly,
      category: category == _sentinel ? this.category : category as String?,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      excludeId: excludeId == _sentinel ? this.excludeId : excludeId as String?,
    );
  }

  bool get isLocationSet => latitude != 0.0 || longitude != 0.0;
}

// Sentinel for nullable copyWith fields
const _sentinel = Object();
