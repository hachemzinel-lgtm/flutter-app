import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? imageUrl;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.s,
          horizontal: AppSpacing.m,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accentBlue : AppColors.cardSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.borderRadius),
            topRight: const Radius.circular(AppSpacing.borderRadius),
            bottomLeft: Radius.circular(isMe ? AppSpacing.borderRadius : 0),
            bottomRight: Radius.circular(isMe ? 0 : AppSpacing.borderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl!),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(timestamp),
              style: AppTextStyles.caption.copyWith(
                color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
