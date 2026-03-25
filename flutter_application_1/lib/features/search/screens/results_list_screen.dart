import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/profile_card.dart';

// Mock provider data — replace with Firestore stream when online
const _allProviders = [
  {
    'name': 'Ahmed Ben Ali',
    'profession': 'Plombier',
    'skills': ['pipe repair', 'leaks', 'emergency plumbing'],
    'rating': 4.9,
    'reviewCount': 87,
    'distanceKm': 1.2,
    'hourlyRate': 35,
    'isAvailable': true,
  },
  {
    'name': 'Khalil Mansour',
    'profession': 'Électricien',
    'skills': ['wiring', 'panels', 'smart home'],
    'rating': 4.7,
    'reviewCount': 53,
    'distanceKm': 2.8,
    'hourlyRate': 40,
    'isAvailable': true,
  },
  {
    'name': 'Sami Trabelsi',
    'profession': 'Peintre',
    'skills': ['interior painting', 'exterior', 'renovation'],
    'rating': 4.5,
    'reviewCount': 31,
    'distanceKm': 4.1,
    'hourlyRate': 25,
    'isAvailable': false,
  },
  {
    'name': 'Omar Jaziri',
    'profession': 'Plombier',
    'skills': ['pipe repair', 'drain cleaning'],
    'rating': 4.2,
    'reviewCount': 19,
    'distanceKm': 6.5,
    'hourlyRate': 30,
    'isAvailable': true,
  },
  {
    'name': 'Rami Chaari',
    'profession': 'Électricien',
    'skills': ['wiring', 'lighting installation'],
    'rating': 3.8,
    'reviewCount': 11,
    'distanceKm': 9.0,
    'hourlyRate': 38,
    'isAvailable': false,
  },
  {
    'name': 'Youssef Hammami',
    'profession': 'Maçon',
    'skills': ['masonry', 'construction', 'tiling'],
    'rating': 4.6,
    'reviewCount': 44,
    'distanceKm': 3.5,
    'hourlyRate': 28,
    'isAvailable': true,
  },
];

class ResultsListScreen extends StatefulWidget {
  final String? initialCategory;
  
  const ResultsListScreen({super.key, this.initialCategory});

  @override
  State<ResultsListScreen> createState() => _ResultsListScreenState();
}

class _ResultsListScreenState extends State<ResultsListScreen> {
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

  int get _activeFilterCount =>
      (_activeDistanceLabel != null ? 1 : 0) +
      (_activeRatingLabel != null ? 1 : 0) +
      (_activeCategoryChip != null ? 1 : 0) +
      (_availableOnly ? 1 : 0);

  List<Map<String, dynamic>> get _filtered {
    return _allProviders.where((p) {
      final dist = (p['distanceKm'] as num).toDouble();
      final rating = (p['rating'] as num).toDouble();
      final available = p['isAvailable'] as bool;
      
      // Category Chip Filter Check
      final matchesCategory = _activeCategoryChip == null || _activeCategoryChip == 'All' ||
          (p['profession'] as String).toLowerCase() == _activeCategoryChip!.toLowerCase() ||
          (p['category'] as String?)?.toLowerCase() == _activeCategoryChip!.toLowerCase();
          
      final q = _query.toLowerCase();
      final matchesText = q.isEmpty ||
          (p['name'] as String).toLowerCase().contains(q) ||
          (p['profession'] as String).toLowerCase().contains(q) ||
          (p['skills'] as List).any((s) => s.toString().toLowerCase().contains(q));
          
      return matchesCategory &&
             matchesText &&
             dist <= _maxDistanceKm &&
             rating >= _minRating &&
             (!_availableOnly || available);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory != 'All') {
      _activeCategoryChip = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim());
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.softGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Filter Results', style: AppTextStyles.headingSmall),
              const SizedBox(height: 20),

              // Distance
              Text(
                'Max Distance: ${tempDist < 100 ? '${tempDist.toStringAsFixed(0)} km' : 'Any'}',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: tempDist, min: 1, max: 100, divisions: 99,
                activeColor: AppColors.accentBlue,
                label: '${tempDist.toStringAsFixed(0)} km',
                onChanged: (v) => setModal(() => tempDist = v),
              ),
              const SizedBox(height: 12),

              // Rating
              Text('Minimum Rating', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _ratingOption('Any', 0.0, tempRating, setModal, (v) => tempRating = v),
                  _ratingOption('3.0+', 3.0, tempRating, setModal, (v) => tempRating = v),
                  _ratingOption('3.5+', 3.5, tempRating, setModal, (v) => tempRating = v),
                  _ratingOption('4.0+', 4.0, tempRating, setModal, (v) => tempRating = v),
                  _ratingOption('4.5+', 4.5, tempRating, setModal, (v) => tempRating = v),
                ],
              ),
              const SizedBox(height: 12),

              // Availability
              CheckboxListTile(
                value: tempAvailable,
                activeColor: AppColors.accentBlue,
                title: Text('Available Now', style: AppTextStyles.bodyLarge),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                      onPressed: () {
                        setState(() {
                          _maxDistanceKm = tempDist;
                          _minRating = tempRating;
                          _availableOnly = tempAvailable;
                          _activeDistanceLabel = tempDist < 100 ? '≤${tempDist.toStringAsFixed(0)} km' : null;
                          _activeRatingLabel = tempRating > 0 ? '${tempRating}+★' : null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply', style: TextStyle(color: Colors.white)),
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

  Widget _ratingOption(String label, double value, double current, StateSetter setModal, Function(double) onSelect) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => setModal(() => onSelect(value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBlue : AppColors.softGray.withOpacity(0.08),
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
        color: AppColors.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 13, color: AppColors.accentBlue)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final filterCount = _activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Experts'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.tune), onPressed: _openFilters),
              if (filterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$filterCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 0),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.softGray.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(color: AppColors.softGray.withOpacity(0.15)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name, profession or skill...',
                  hintStyle: AppTextStyles.bodyMedium,
                  prefixIcon: const Icon(Icons.search, color: AppColors.softGray, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppColors.softGray, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // Active filter chips
          if (_activeDistanceLabel != null || _activeRatingLabel != null || _activeCategoryChip != null || _availableOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.m, 8, AppSpacing.m, 0),
              child: Wrap(
                children: [
                  if (_activeCategoryChip != null)
                    _activeChip(_activeCategoryChip!, () => setState(() => _activeCategoryChip = null)),
                  if (_activeDistanceLabel != null)
                    _activeChip(_activeDistanceLabel!, () => setState(() { _maxDistanceKm = 100; _activeDistanceLabel = null; })),
                  if (_activeRatingLabel != null)
                    _activeChip(_activeRatingLabel!, () => setState(() { _minRating = 0; _activeRatingLabel = null; })),
                  if (_availableOnly)
                    _activeChip('Available Now', () => setState(() => _availableOnly = false)),
                ],
              ),
            ),

          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 6),
            child: Text(
              '${results.length} expert${results.length == 1 ? '' : 's'} found',
              style: AppTextStyles.bodyMedium,
            ),
          ),

          // List or empty state
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: AppColors.softGray),
                        const SizedBox(height: 16),
                        Text('No results found', style: AppTextStyles.headingSmall.copyWith(color: AppColors.softGray)),
                        const SizedBox(height: 8),
                        Text('Try adjusting your search or filters', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: AppSpacing.pagePadding,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final p = results[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileCard(
                            name: p['name'] as String,
                            profession: p['profession'] as String,
                            heroTag: 'result_$index',
                            rating: (p['rating'] as num).toDouble(),
                            reviewCount: p['reviewCount'] as int,
                            isAvailable: p['isAvailable'] as bool,
                            onTap: () => context.push('/provider-profile/mock_$index'),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, left: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.softGray),
                                const SizedBox(width: 3),
                                Text('${(p['distanceKm'] as num).toStringAsFixed(1)} km', style: AppTextStyles.caption),
                                const SizedBox(width: 12),
                                const Icon(Icons.access_time, size: 13, color: AppColors.softGray),
                                const SizedBox(width: 3),
                                Text('${p['hourlyRate']} DT/hr', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
