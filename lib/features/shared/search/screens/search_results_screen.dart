import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../models/search_filter_model.dart';
import '../providers/search_results_provider.dart';

class SearchResultsScreen extends ConsumerWidget {
  final SearchFilterModel filter;
  const SearchResultsScreen({super.key, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider(filter));

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
        title: Text('Results',
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.primaryNavy)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.primaryNavy),
            tooltip: 'Change Filters',
            onPressed: () => context.pop(), // go back to filter screen
          ),
        ],
      ),
      body: resultsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.electricBlue),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
                const SizedBox(height: 12),
                Text('Something went wrong',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.primaryNavy)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.errorRed)),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(searchResultsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off,
                        size: 64,
                        color: AppColors.softGray.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('No results found',
                        style: AppTextStyles.headingSmall
                            .copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Try adjusting your filters',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.softGray)),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.tune, color: AppColors.electricBlue),
                      label: const Text('Change Filters',
                          style: TextStyle(color: AppColors.electricBlue)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.electricBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              return _ResultCard(
                data: results[i],
                target: filter.target,
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result Card
// ---------------------------------------------------------------------------
class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String target;
  const _ResultCard({required this.data, required this.target});

  bool get _isWp => target == 'work_provider';

  String get _displayName {
    if (_isWp) {
      final first = data['firstName'] as String? ?? '';
      final last = data['lastName'] as String? ?? '';
      return '$first $last'.trim();
    }
    return data['shopName'] as String? ?? '';
  }

  String get _displayRole {
    if (_isWp) return data['profession'] as String? ?? '';
    return data['shopCategory'] as String? ?? '';
  }

  String get _initials {
    final n = _displayName;
    if (n.isEmpty) return '?';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final uid = data['uid'] as String? ?? '';
    final imageUrl =
        data['profileImageUrl'] as String? ?? data['photoUrl'] as String?;
    final locationName = data['locationName'] as String? ??
        data['city'] as String? ?? '';
    final rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
    final isVerified = (data['isVerified'] as bool?) ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryNavy,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? Text(_initials,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))
                    : null,
              ),
              if (_isWp && isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.authenticGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.star, color: AppColors.white, size: 10),
                  ),
                ),
            ],
          ),

          // ── Info ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName,
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(_displayRole,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.softGray, fontSize: 13)),
                  if (locationName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.softGray),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.softGray)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  reviewCount >= 3
                      ? _StarRatingRow(rating: rating, reviewCount: reviewCount)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.electricBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('New',
                              style: TextStyle(
                                  color: AppColors.electricBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ),
          ),

          // ── Right column ─────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isWp && isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.availableGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✓ Verified',
                      style: TextStyle(
                          color: AppColors.availableGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (_isWp) {
                      context.push('/provider-profile/$uid');
                    } else {
                      context.push('/merchant-profile/$uid');
                    }
                  },
                  child: const Text('View',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  final double rating;
  final int reviewCount;
  const _StarRatingRow({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: i < filled ? AppColors.authenticGold : AppColors.softGray,
          );
        }),
        const SizedBox(width: 4),
        Text(
          '★ ${rating.toStringAsFixed(1)} · $reviewCount reviews',
          style: AppTextStyles.caption.copyWith(color: AppColors.softGray),
        ),
      ],
    );
  }
}
