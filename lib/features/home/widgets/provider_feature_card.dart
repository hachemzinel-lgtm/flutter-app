import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/verified_badge.dart';

class ProviderFeatureCard extends StatelessWidget {
  const ProviderFeatureCard({
    super.key,
    required this.name,
    required this.profession,
    required this.rating,
    this.distance,
    this.photoUrl,
    this.isVerified = false,
    this.isAvailable = false,
    required this.onTap,
  });

  final String name;
  final String profession;
  final double rating;
  final String? distance;
  final String? photoUrl;
  final bool isVerified;
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                  backgroundImage: photoUrl == null
                      ? null
                      : NetworkImage(photoUrl!),
                  child: photoUrl == null
                      ? Text(
                          name.substring(0, 1).toUpperCase(),
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.accentBlue,
                          ),
                        )
                      : null,
                ),
                if (isVerified)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: VerifiedBadge(size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              profession,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.starGold,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  rating == 0 ? 'New' : rating.toStringAsFixed(1),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (distance != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• $distance',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.softGray,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.availableGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Available Now',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.availableGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
