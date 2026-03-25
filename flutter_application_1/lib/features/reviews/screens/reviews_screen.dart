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

class ReviewsScreen extends ConsumerWidget {
  final String providerId;
  const ReviewsScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = StreamProvider((ref) => ref.watch(reviewServiceProvider).getReviews(providerId));
    final reviewsSnapshot = ref.watch(reviewsAsync);

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: reviewsSnapshot.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) return const Center(child: Text('No reviews yet.'));
          
          return ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.docs[index].data() as Map<String, dynamic>;
              return _buildReviewTile(data);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
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
              Text(data['reviewerName'] ?? 'Anonymous', style: AppTextStyles.headingSmall),
              Text(
                timeago.format((data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingBarIndicator(
            rating: (data['rating'] ?? 0.0).toDouble(),
            itemBuilder: (context, index) => const Icon(Icons.star, color: AppColors.starGold),
            itemCount: 5,
            itemSize: 16,
          ),
          const SizedBox(height: 12),
          Text(data['comment'] ?? '', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
