import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.onActionTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.softGray.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.headingSmall,
              ),
              if (onActionTap != null && actionLabel != null)
                TextButton(
                  onPressed: onActionTap,
                  child: Text(
                    actionLabel!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}
