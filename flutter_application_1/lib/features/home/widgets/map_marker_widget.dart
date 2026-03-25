import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MapMarkerWidget extends StatelessWidget {
  final double rating;
  final String? imageUrl;
  final VoidCallback onTap;

  const MapMarkerWidget({
    super.key,
    required this.rating,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Marker Background (Outer Glow/Circle)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          // Profile Photo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentBlue, width: 2),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.person, color: AppColors.softGray),
            ),
          ),
          // Rating Badge
          Positioned(
            top: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.starGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 10, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
