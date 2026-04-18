import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/search_filter_provider.dart';

// ---------------------------------------------------------------------------
// Category lists
// ---------------------------------------------------------------------------
const _wpCategories = [
  'Any', 'Plumber', 'Electrician', 'Cleaner', 'Carpenter', 'Painter',
  'Mason', 'Welder', 'AC Technician', 'Tile Layer', 'Roofer',
  'Locksmith', 'Gardener', 'Pest Control', 'Security System',
];

const _mpCategories = [
  'Any', 'Materials Supplier', 'Tools & Equipment', 'Spare Parts',
  'General Hardware', 'Paint & Finishes', 'Electrical Supplies',
  'Plumbing Supplies', 'Tiles & Flooring', 'Safety Equipment',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class SearchFilterScreen extends ConsumerStatefulWidget {
  final String target;
  final String? excludeId;
  const SearchFilterScreen({super.key, required this.target, this.excludeId});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  bool _locating = false;

  ({String target, String? excludeId}) get _key =>
      (target: widget.target, excludeId: widget.excludeId);

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider(_key));
    final notifier = ref.read(searchFilterProvider(_key).notifier);
    final isWp = widget.target == 'work_provider';
    final categories = isWp ? _wpCategories : _mpCategories;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          color: AppColors.primaryNavy,
          onPressed: () => context.pop(),
        ),
        title: Text('Search Filters',
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.primaryNavy)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ── CARD 1: Location ─────────────────────────────
          _SectionCard(
            title: 'Your Location',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filter.locationName.isNotEmpty
                        ? filter.locationName
                        : 'Tap to set location',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: filter.locationName.isNotEmpty
                          ? AppColors.primaryNavy
                          : AppColors.softGray,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _locating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.electricBlue))
                    : TextButton.icon(
                        icon: const Icon(Icons.my_location, size: 16,
                            color: AppColors.electricBlue),
                        label: const Text('Use My Location',
                            style: TextStyle(color: AppColors.electricBlue, fontSize: 12)),
                        onPressed: () async {
                          setState(() => _locating = true);
                          try {
                            await notifier.useCurrentLocation();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()),
                                    backgroundColor: AppColors.errorRed),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _locating = false);
                          }
                        },
                      ),
              ],
            ),
          ),

          // ── CARD 2: Radius ────────────────────────────────
          _SectionCard(
            title: 'Search Radius',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${filter.radiusKm.round()} km',
                  style: const TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            child: Slider(
              value: filter.radiusKm,
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: AppColors.electricBlue,
              onChanged: notifier.setRadius,
            ),
          ),

          // ── CARD 3: Min Rating ────────────────────────────
          _SectionCard(
            title: 'Minimum Rating',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    final filled = starIndex <= filter.minRating;
                    return GestureDetector(
                      onTap: () {
                        if (filter.minRating == starIndex) {
                          notifier.setMinRating(0);
                        } else {
                          notifier.setMinRating(starIndex);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: filled ? AppColors.authenticGold : AppColors.softGray,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  filter.minRating == 0
                      ? 'Any rating'
                      : '${filter.minRating}★ and above',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.softGray),
                ),
              ],
            ),
          ),

          // ── CARD 4: Availability ──────────────────────────
          _SectionCard(
            title: isWp ? 'Availability' : 'Availability',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isWp ? 'Available now only' : 'Open now only',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primaryNavy),
                  ),
                ),
                Switch(
                  value: filter.availableOnly,
                  onChanged: notifier.setAvailableOnly,
                  activeTrackColor: AppColors.electricBlue,
                ),
              ],
            ),
          ),

          // ── CARD 5: Category ──────────────────────────────
          _SectionCard(
            title: isWp ? 'Profession / Category' : 'Store Category',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = (filter.category ?? 'Any') == cat;
                return GestureDetector(
                  onTap: () => notifier.setCategory(cat == 'Any' ? null : cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.electricBlue
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.electricBlue
                            : AppColors.primaryNavy.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.primaryNavy,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── CARD 6: Verified (WP only) ────────────────────
          if (isWp)
            _SectionCard(
              title: 'Verified',
              child: Row(
                children: [
                  Expanded(
                    child: Text('Verified providers only',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.primaryNavy)),
                  ),
                  Switch(
                    value: filter.verifiedOnly,
                    onChanged: notifier.setVerifiedOnly,
                    activeTrackColor: AppColors.electricBlue,
                  ),
                ],
              ),
            ),
        ],
      ),

      // ── Pinned Search Button ────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () {
                if (!filter.isLocationSet) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please set your location first'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                  return;
                }
                context.push('/search-results', extra: filter);
              },
              child: const Text('Search',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable section card
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.bold)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
