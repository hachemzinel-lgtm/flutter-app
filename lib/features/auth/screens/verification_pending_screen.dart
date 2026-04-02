import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';

class VerificationPendingScreen extends ConsumerWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDocProvider);
    final verificationReason = userAsync.value?.toJson()['verificationReason'] as String?;
    final status = userAsync.value?.toJson()['verificationStatus'] as String?;
    final isRejected = status == 'rejected';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: (isRejected ? AppColors.errorRed : AppColors.starGold).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isRejected ? AppColors.errorRed : AppColors.starGold).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isRejected ? Icons.gpp_bad_outlined : Icons.schedule_rounded,
                  size: 56,
                  color: isRejected ? AppColors.errorRed : AppColors.starGold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                isRejected ? 'Documents Rejected' : 'Verification Pending',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                isRejected
                    ? 'Your documents could not be verified. Please re-upload valid certificates.'
                    : 'Your documents are being reviewed. You\'ll be notified once approved.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (verificationReason != null && verificationReason.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.l),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.errorRed, size: 18),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(
                          'Reason: $verificationReason',
                          style: AppTextStyles.caption.copyWith(color: AppColors.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (isRejected)
                PrimaryButton(
                  text: 'Re-upload Documents',
                  onPressed: () => context.push('/profile-setup/provider'),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue)),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(
                          'Checking verification status automatically...',
                          style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.l),
              TextButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                child: Text('Sign Out', style: AppTextStyles.caption.copyWith(color: AppColors.softGray)),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }
}
