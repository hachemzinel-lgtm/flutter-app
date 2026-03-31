import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/verified_badge.dart';

class ProviderFeatureCard extends StatelessWidget {
  final String name;
  final String profession;
  final double rating;
  final String? distance;
  final String? photoUrl;
  final bool isVerified;
  final bool isAvailable;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accentBlue.withOpacity(0.1),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null 
                      ? Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentBlue)) 
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
            const SizedBox(height: 8),
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              profession,
              style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.starGold, size: 14),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                if (distance != null) ...[
                  const SizedBox(width: 4),
                  Text('• $distance', style: AppTextStyles.caption.copyWith(color: AppColors.softGray)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.availableGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Available Now',
                  style: AppTextStyles.caption.copyWith(color: AppColors.availableGreen, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
