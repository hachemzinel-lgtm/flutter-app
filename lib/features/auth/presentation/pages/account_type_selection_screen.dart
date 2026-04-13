import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/account_type_controller.dart';
import '../../providers/auth_action_state.dart';

class AccountTypeSelectionScreen extends ConsumerStatefulWidget {
  const AccountTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountTypeSelectionScreen> createState() =>
      _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState
    extends ConsumerState<AccountTypeSelectionScreen> {
  String? _selectedType;

  Future<void> _continue() async {
    if (_selectedType == null) return;

    final route = await ref
        .read(accountTypeControllerProvider.notifier)
        .saveSelection(_selectedType!);

    if (mounted && route != null) {
      context.go(route);
    }
  }

  // â”€â”€ Card builder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Bug 1 Fix: withValues(alpha:) instead of withOpacity()
          color: isSelected
              ? AppColors.accentBlue.withValues(alpha: 0.1)
              : AppColors.cardSurface,
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Bug 1 Fix: withValues(alpha:) instead of withOpacity()
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.accentBlue),
            ),
            const SizedBox(height: 14),
            Text(title, style: AppTextStyles.headingSmall),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softGray,
                fontSize: 13,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              const Icon(
                LucideIcons.checkCircle,
                color: AppColors.accentBlue,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthActionState>(accountTypeControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    });

    final state = ref.watch(accountTypeControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                'Choose Your Account Type',
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you want to use NearWork.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.softGray,
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTypeCard(
                        type: 'client',
                        icon: LucideIcons.user,
                        title: 'Client',
                        description:
                            'Find trusted local workers and marketplace merchants near you.',
                      ),
                      const SizedBox(height: 16),
                      _buildTypeCard(
                        type: 'workProvider',
                        icon: LucideIcons.briefcase,
                        title: 'Work Provider',
                        description:
                            'Offer your professional skills and services to nearby clients.',
                      ),
                      const SizedBox(height: 16),
                      _buildTypeCard(
                        type: 'marketplace',
                        icon: LucideIcons.store,
                        title: 'Marketplace',
                        description:
                            'Showcase your local business and products to the community.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: (_selectedType == null || isLoading)
                      ? null
                      : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
