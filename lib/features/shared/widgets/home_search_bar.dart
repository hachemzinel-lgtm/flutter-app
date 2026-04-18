import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class HomeSearchBar extends StatelessWidget {
  final String placeholder;
  final ValueChanged<String> onSubmit;
  final String? userAvatarUrl;

  const HomeSearchBar({
    super.key,
    required this.placeholder,
    required this.onSubmit,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray),
          prefixIcon: const Icon(Icons.search, color: AppColors.electricBlue),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: CircleAvatar(
              backgroundColor: AppColors.softGray.withValues(alpha: 0.2),
              backgroundImage: userAvatarUrl != null ? NetworkImage(userAvatarUrl!) : null,
              child: userAvatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.softGray, size: 20)
                  : null,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
