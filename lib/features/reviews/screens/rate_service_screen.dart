import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import 'reviews_screen.dart';

class RateServiceScreen extends ConsumerStatefulWidget {
  final String providerId;
  const RateServiceScreen({super.key, required this.providerId});

  @override
  ConsumerState<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends ConsumerState<RateServiceScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Service')),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Text('How was your experience?', style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.xxl),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: AppColors.starGold),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe your experience...',
                filled: true,
                fillColor: AppColors.softGray.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Submit Review',
              onPressed: () async {
                final user = ref.read(authStateProvider).value;
                if (user == null) return;

                await ref.read(reviewServiceProvider).submitReview(
                  providerId: widget.providerId,
                  reviewerId: user.uid,
                  reviewerName: user.displayName ?? 'Anonymous',
                  rating: _rating,
                  comment: _commentController.text,
                );
                if (mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
