import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class MapProviderMarker extends StatelessWidget {
  final String? profileImageUrl;
  final double? averageRating;
  final int? reviewCount;
  final bool isTopRated; // uses gold border instead of blue

  const MapProviderMarker({
    super.key,
    this.profileImageUrl,
    this.averageRating,
    this.reviewCount,
    this.isTopRated = false,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = averageRating != null && reviewCount != null && reviewCount! >= 3;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            border: Border.all(
              color: isTopRated ? AppColors.authenticGold : AppColors.electricBlue,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: AppColors.softGray.withValues(alpha: 0.2),
            backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
            child: profileImageUrl == null
                ? const Icon(Icons.person, color: AppColors.softGray)
                : null,
          ),
        ),
        if (showBadge)
          Positioned(
            top: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.authenticGold,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: AppColors.white, size: 10),
                  const SizedBox(width: 2),
                  Text(
                    averageRating!.toStringAsFixed(1),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
