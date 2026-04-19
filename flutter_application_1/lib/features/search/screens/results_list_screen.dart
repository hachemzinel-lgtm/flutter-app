import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/distance_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/profile_card.dart';

/// Live stream of all available providers. The home screen already uses a
/// similar stream (`providersStreamProvider`); we keep a dedicated one here
/// because this screen may evolve filters independently (e.g. hourlyRate).
final _searchableProvidersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('providers')
      .limit(200)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['uid'] = doc.id;
            return data;
          }).toList());
});

class ResultsListScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const ResultsListScreen({super.key, this.initialCategory});

  @override
  ConsumerState<ResultsListScreen> createState() =>
      _ResultsListScreenState();
}

class _ResultsListScreenState extends ConsumerState<ResultsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _activeCategoryChip;

  // Filters
  double _maxDistanceKm = 100.0;
  double _minRating = 0.0;
  bool _availableOnly = false;

  // Active filter labels for chips
  String? _activeDistanceLabel;
  String? _activeRatingLabel;

  // User location (for distance filtering / display)
  LatLng? _userLocation;

  int get _activeFilterCount =>
      (_activeDistanceLabel != null ? 1 : 0) +
      (_activeRatingLabel != null ? 1 : 0) +
      (_activeCategoryChip != null ? 1 : 0) +
      (_availableOnly ? 1 : 0);

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null &&
        widget.initialCategory != 'All') {
      _activeCategoryChip = widget.initialCategory;
    }
    _loadUserLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final pos = await LocationService().getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> src) {
    final q = _query.toLowerCase();
    final userLat = _userLocation?.latitude;
    final userLng = _userLocation?.longitude;

    final withDistance = src.map((p) {
      final lat = (p['lat'] as num?)?.toDouble();
      final lng = (p['lng'] as num?)?.toDouble();
      double? distKm;
      if (lat != null && lng != null && userLat != null && userLng != null) {
        distKm = DistanceService()
            .calculateDistance(lat, lng, userLat, userLng);
      }
      return {...p, 'distanceKm': distKm};
    });

    return withDistance.where((p) {
      // Category
      final profession =
          (p['profession'] as String?)?.toLowerCase() ?? '';
      final category =
          (p['category'] as String?)?.toLowerCase() ?? '';
      final matchesCategory = _activeCategoryChip == null ||
          _activeCategoryChip == 'All' ||
          profession == _activeCategoryChip!.toLowerCase() ||
          category == _activeCategoryChip!.toLowerCase();

      // Free-text search across name, profession, skills.
      final name = (p['name'] as String?)?.toLowerCase() ?? '';
      final skills = (p['skills'] as List?)
              ?.map((s) => s.toString().toLowerCase())
              .toList() ??
          const <String>[];
      final matchesText = q.isEmpty ||
          name.contains(q) ||
          profession.contains(q) ||
          skills.any((s) => s.contains(q));

      // Rating
      final rating = ((p['rating'] as num?) ?? 0).toDouble();
      final matchesRating = rating >= _minRating;

      // Availability
      final available = (p['isAvailable'] as bool?) ?? true;
      final matchesAvailability = !_availableOnly || available;

      // Distance — only enforced if we know both sides.
      final dist = p['distanceKm'] as double?;
      final matchesDistance = dist == null || dist <= _maxDistanceKm;

      return matchesCategory &&
          matchesText &&
          matchesRating &&
          matchesAvailability &&
          matchesDistance;
    }).toList()
      ..sort((a, b) {
        final da = a['distanceKm'] as double?;
        final db = b['distanceKm'] as double?;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
  }

  void _openFilters() {
    double tempDist = _maxDistanceKm;
    double tempRating = _minRating;
    bool tempAvailable = _availableOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.l,
            right: AppSpacing.l,
            top: AppSpacing.m,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.softGray.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Filter Results', style: AppTextStyles.headingSmall),
              const SizedBox(height: 20),
              Text(
                'Max Distance: ${tempDist < 100 ? '${tempDist.toStringAsFixed(0)} km' : 'Any'}',
                style: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: tempDist,
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: AppColors.accentBlue,
                label: '${tempDist.toStringAsFixed(0)} km',
                onChanged: (v) => setModal(() => tempDist = v),
              ),
              const SizedBox(height: 12),
              Text('Minimum Rating',
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _ratingOption('Any', 0.0, tempRating, setModal,
                      (v) => tempRating = v),
                  _ratingOption('3.0+', 3.0, tempRating, setModal,
                      (v) => tempRating = v),
                  _ratingOption('3.5+', 3.5, tempRating, setModal,
                      (v) => tempRating = v),
                  _ratingOption('4.0+', 4.0, tempRating, setModal,
                      (v) => tempRating = v),
                  _ratingOption('4.5+', 4.5, tempRating, setModal,
                      (v) => tempRating = v),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: tempAvailable,
                activeColor: AppColors.accentBlue,
                title:
                    Text('Available Now', style: AppTextStyles.bodyLarge),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setModal(() => tempAvailable = v ?? false),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _maxDistanceKm = 100;
                          _minRating = 0;
                          _availableOnly = false;
                          _activeDistanceLabel = null;
                          _activeRatingLabel = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue),
                      onPressed: () {
                        setState(() {
                          _maxDistanceKm = tempDist;
                          _minRating = tempRating;
                          _availableOnly = tempAvailable;
                          _activeDistanceLabel = tempDist < 100
                              ? '≤${tempDist.toStringAsFixed(0)} km'
                              : null;
                          _activeRatingLabel = tempRating > 0
                              ? '${tempRating.toStringAsFixed(1)}+★'
                              : null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratingOption(
    String label,
    double value,
    double current,
    StateSetter setModal,
    void Function(double) onSelect,
  ) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => setModal(() => onSelect(value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentBlue
              : AppColors.softGray.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 13, color: AppColors.accentBlue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(_searchableProvidersProvider);
    final filterCount = _activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Experts'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.tune), onPressed: _openFilters),
              if (filterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.errorRed, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$filterCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: providersAsync.when(
        data: (all) {
          final results = _applyFilters(all);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m, AppSpacing.m, AppSpacing.m, 0),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.softGray.withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadius),
                    border: Border.all(
                        color: AppColors.softGray.withValues(alpha: 0.15)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText:
                          'Search by name, profession or skill...',
                      hintStyle: AppTextStyles.bodyMedium,
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.softGray, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.softGray, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              if (_activeDistanceLabel != null ||
                  _activeRatingLabel != null ||
                  _activeCategoryChip != null ||
                  _availableOnly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.m, 8, AppSpacing.m, 0),
                  child: Wrap(
                    children: [
                      if (_activeCategoryChip != null)
                        _activeChip(
                            _activeCategoryChip!,
                            () => setState(
                                () => _activeCategoryChip = null)),
                      if (_activeDistanceLabel != null)
                        _activeChip(_activeDistanceLabel!, () {
                          setState(() {
                            _maxDistanceKm = 100;
                            _activeDistanceLabel = null;
                          });
                        }),
                      if (_activeRatingLabel != null)
                        _activeChip(_activeRatingLabel!, () {
                          setState(() {
                            _minRating = 0;
                            _activeRatingLabel = null;
                          });
                        }),
                      if (_availableOnly)
                        _activeChip('Available Now',
                            () => setState(() => _availableOnly = false)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m, vertical: 6),
                child: Text(
                  '${results.length} expert${results.length == 1 ? '' : 's'} found',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? _buildEmptyResults()
                    : ListView.builder(
                        padding: AppSpacing.pagePadding,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final p = results[index];
                          final uid = p['uid'] as String;
                          final distance = p['distanceKm'] as double?;
                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              ProfileCard(
                                name:
                                    (p['name'] as String?) ?? 'Provider',
                                profession:
                                    (p['profession'] as String?) ?? '',
                                photoUrl: p['photoUrl'] as String?,
                                heroTag: 'result_$uid',
                                rating:
                                    ((p['rating'] as num?) ?? 0).toDouble(),
                                reviewCount:
                                    ((p['reviewCount'] as num?) ?? 0)
                                        .toInt(),
                                isAvailable:
                                    (p['isAvailable'] as bool?) ?? true,
                                onTap: () =>
                                    context.push('/provider-profile/$uid'),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 10, left: 4),
                                child: Row(
                                  children: [
                                    if (distance != null) ...[
                                      const Icon(Icons.location_on_outlined,
                                          size: 13,
                                          color: AppColors.softGray),
                                      const SizedBox(width: 3),
                                      Text(
                                          '${distance.toStringAsFixed(1)} km',
                                          style: AppTextStyles.caption),
                                      const SizedBox(width: 12),
                                    ],
                                    if (p['hourlyRate'] != null) ...[
                                      const Icon(Icons.access_time,
                                          size: 13,
                                          color: AppColors.softGray),
                                      const SizedBox(width: 3),
                                      Text('${p['hourlyRate']} DT/hr',
                                          style: AppTextStyles.caption),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load experts: $e',
              style: AppTextStyles.bodyMedium),
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off,
              size: 64, color: AppColors.softGray),
          const SizedBox(height: 16),
          Text('No results found',
              style: AppTextStyles.headingSmall
                  .copyWith(color: AppColors.softGray)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filters',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
