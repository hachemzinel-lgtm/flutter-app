import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MapMarkerWidget extends StatelessWidget {
  final double rating;
  final String? imageUrl;
  final String category;
  final VoidCallback onTap;

  const MapMarkerWidget({
    super.key,
    required this.rating,
    this.imageUrl,
    this.category = '',
    required this.onTap,
  });

  Color get _markerColor {
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('plumber')) return const Color(0xFF007AFF);
    if (lowerCat.contains('electrician')) return const Color(0xFFFFCC00);
    if (lowerCat.isNotEmpty && lowerCat != 'unknown') return const Color(0xFF34C759);
    return const Color(0xFFFF3B30); // Default Red
  }

  @override
  Widget build(BuildContext context) {
    final color = _markerColor;

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
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          // Profile Photo or pin dot
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color, // Usually white, but using color for distinction
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.person, color: Colors.white, size: 24),
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
