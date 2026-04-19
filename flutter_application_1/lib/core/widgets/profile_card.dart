import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import 'star_rating_row.dart';
import 'availability_badge.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String profession;
  final String? photoUrl;
  final String? heroTag;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.name,
    required this.profession,
    this.photoUrl,
    this.heroTag,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: heroTag ?? 'profile_$name',
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.softGray.withOpacity(0.2),
                backgroundImage: photoUrl != null
                    ? CachedNetworkImageProvider(photoUrl!)
                    : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, color: AppColors.softGray)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.headingSmall,
                      ),
                      AvailabilityBadge(isAvailable: isAvailable),
                    ],
                  ),
                  Text(
                    profession,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  StarRatingRow(rating: rating, reviewCount: reviewCount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
