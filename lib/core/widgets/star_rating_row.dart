import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

class StarRatingRow extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double iconSize;

  const StarRatingRow({
    super.key,
    required this.rating,
    this.reviewCount,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, index) =>
              const Icon(Icons.star, color: AppColors.starGold),
          itemCount: 5,
          itemSize: iconSize,
          direction: Axis.horizontal,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text('($reviewCount)', style: AppTextStyles.caption),
        ],
      ],
    );
  }
}
