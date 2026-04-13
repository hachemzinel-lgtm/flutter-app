class SearchParams {
  final String targetType;        // "work_provider" | "marketplace"
  final String? searchQuery;
  final int radius;               // km, default 10
  final List<String> categories;  // empty = all
  final double minRating;         // 0.0 = no filter
  final bool verifiedOnly;        // default false
  final bool availableOnly;       // default false
  final String? excludeUid;       // exclude own profile (MP searching MP)
  final String? presetCategory;   // from AI chatbot

  SearchParams({
    required this.targetType,
    this.searchQuery,
    this.radius = 10,
    this.categories = const [],
    this.minRating = 0.0,
    this.verifiedOnly = false,
    this.availableOnly = false,
    this.excludeUid,
    this.presetCategory,
  });
}
