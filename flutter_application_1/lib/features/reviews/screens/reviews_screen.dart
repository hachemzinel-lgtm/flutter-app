import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/review_service.dart';

final reviewServiceProvider = Provider((ref) => ReviewService());

/// Stable, family-keyed stream provider for a given target's reviews.
/// Keeps a single Firestore subscription alive regardless of widget rebuilds.
final reviewsStreamProvider = StreamProvider.family<
    QuerySnapshot<Map<String, dynamic>>,
    ({String id, ReviewTarget target})>((ref, key) {
  return ref.watch(reviewServiceProvider).getReviews(key.id, target: key.target);
});

class ReviewsScreen extends ConsumerWidget {
  final String providerId;
  final ReviewTarget target;
  const ReviewsScreen({
    super.key,
    required this.providerId,
    this.target = ReviewTarget.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsSnapshot = ref.watch(
      reviewsStreamProvider((id: providerId, target: target)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: reviewsSnapshot.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(child: Text('No reviews yet.'));
          }

          return ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.docs[index].data();
              return _buildReviewTile(data);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softGray.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (data['reviewerName'] as String?) ?? 'Anonymous',
                style: AppTextStyles.headingSmall,
              ),
              Text(
                timeago.format(
                  (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                ),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingBarIndicator(
            rating: ((data['rating'] as num?) ?? 0).toDouble(),
            itemBuilder: (_, __) =>
                const Icon(Icons.star, color: AppColors.starGold),
            itemCount: 5,
            itemSize: 16,
          ),
          const SizedBox(height: 12),
          Text(
            (data['comment'] as String?) ?? '',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
