import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

class ConversationTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final DateTime timestamp;
  final String? photoUrl;
  final int unreadCount;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    this.photoUrl,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.softGray.withOpacity(0.2),
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl!)
            : null,
        child: photoUrl == null
            ? const Icon(Icons.person, color: AppColors.softGray)
            : null,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          Text(
            DateFormat.jm().format(timestamp),
            style: AppTextStyles.caption.copyWith(
              color: unreadCount > 0 ? AppColors.accentBlue : AppColors.textLight,
              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: unreadCount > 0 ? AppColors.textDark : AppColors.textLight,
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.accentBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
