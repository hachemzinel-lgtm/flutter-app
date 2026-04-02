import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/review_service.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({
    super.key,
    required this.providerId,
  });

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Reviews')),
      body: StreamBuilder(
        stream: ReviewService().getReviews(providerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load reviews.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.errorRed,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data!;
          if (reviews.isEmpty) {
            return Center(
              child: Text(
                'No reviews yet.',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: reviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
                          backgroundImage: review.reviewerPhoto.isEmpty
                              ? null
                              : NetworkImage(review.reviewerPhoto),
                          child: review.reviewerPhoto.isEmpty
                              ? Text(
                                  review.reviewerName.substring(0, 1).toUpperCase(),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.reviewerName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              Text(
                                review.createdAt.toIso8601String().split('T').first,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.starGold,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      review.text.isEmpty ? 'No written review.' : review.text,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    if (review.response != null && review.response!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.m),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Response',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              review.response!,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
