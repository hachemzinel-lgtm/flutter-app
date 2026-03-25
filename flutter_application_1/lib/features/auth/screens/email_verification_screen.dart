import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/ghost_button.dart';

class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Verify Your Email',
              style: AppTextStyles.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'We sent a verification link to your email address. Please click the link to activate your account.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              text: 'I have verified my email',
              onPressed: () {
                // In a real app, reload user and check emailVerified
                context.go('/home');
              },
            ),
            const SizedBox(height: AppSpacing.m),
            GhostButton(
              text: 'Resend Email',
              onPressed: () {
                // Logic to resend email
              },
            ),
          ],
        ),
      ),
    );
  }
}
