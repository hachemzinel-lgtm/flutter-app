import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/star_rating_row.dart';

class ProviderPopupCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final double distanceKm;

  const ProviderPopupCard({
    super.key,
    required this.provider,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final String uid = provider['uid'] ?? 'mock_id';
    final String name = provider['name'] ?? 'Unknown';
    final String profession = provider['profession'] ?? provider['category'] ?? '';
    final double rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = (provider['reviewCount'] as num?)?.toInt() ?? 0;
    final bool isAvailable = provider['isAvailable'] as bool? ?? false;
    final String? hourlyRate = provider['hourlyRate']?.toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.l),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.softGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Provider info row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.softGray.withOpacity(0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.headingSmall.copyWith(color: AppColors.accentBlue),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.headingSmall),
                    Text(profession, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
                    const SizedBox(height: 4),
                    StarRatingRow(rating: rating, reviewCount: reviewCount),
                  ],
                ),
              ),
              // Availability badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isAvailable ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Busy',
                  style: AppTextStyles.caption.copyWith(
                    color: isAvailable ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.m),

          // Info chips row
          Row(
            children: [
              _infoChip(Icons.location_on_outlined, '${distanceKm.toStringAsFixed(1)} km away'),
              const SizedBox(width: AppSpacing.s),
              if (hourlyRate != null)
                _infoChip(Icons.attach_money, '$hourlyRate /hr'),
            ],
          ),

          const SizedBox(height: AppSpacing.l),

          PrimaryButton(
            text: 'View Full Profile',
            onPressed: () {
              Navigator.pop(context);
              context.push('/provider-profile/$uid');
            },
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softGray.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentBlue),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textDark)),
        ],
      ),
    );
  }
}
