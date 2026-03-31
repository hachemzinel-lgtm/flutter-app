import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/review_model.dart';
import '../../../services/review_service.dart';

class ReviewsScreen extends ConsumerWidget {
  final String providerId;
  const ReviewsScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Reviews')),
      body: StreamBuilder<List<ReviewModel>>(
        stream: ReviewService().getReviews(providerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading reviews'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final reviews = snapshot.data!;
          if (reviews.isEmpty) return const Center(child: Text('No reviews yet.'));

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (ctx, i) {
              final r = reviews[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: r.reviewerPhoto.isNotEmpty ? NetworkImage(r.reviewerPhoto) : null,
                        child: r.reviewerPhoto.isEmpty ? Text(r.reviewerName[0].toUpperCase()) : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.reviewerName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text(r.createdAt.toString().split(' ')[0], style: AppTextStyles.caption.copyWith(color: AppColors.softGray)),
                          ],
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: AppColors.starGold, size: 18),
                      Text(r.rating.toString(), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(r.text, style: AppTextStyles.bodyMedium),
                  if (r.response != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Provider Response:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                          const SizedBox(height: 4),
                          Text(r.response!, style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
