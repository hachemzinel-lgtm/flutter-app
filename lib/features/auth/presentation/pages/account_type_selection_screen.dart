import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/auth_action_state.dart';
import '../../providers/account_type_controller.dart';

class AccountTypeSelectionScreen extends ConsumerStatefulWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  ConsumerState<AccountTypeSelectionScreen> createState() =>
      _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState
    extends ConsumerState<AccountTypeSelectionScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthActionState>(accountTypeControllerProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    });

    final state = ref.watch(accountTypeControllerProvider);

    Future<void> continueFlow() async {
      if (_selectedType == null) {
        return;
      }

      final route = await ref
          .read(accountTypeControllerProvider.notifier)
          .saveSelection(_selectedType!);
      if (context.mounted && route != null) {
        context.go(route);
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your Account Type',
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Select how you want to use NearWork.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              _AccountTypeCard(
                title: 'Client',
                description: 'Looking for services or products',
                icon: Icons.person_outline_rounded,
                selected: _selectedType == 'client',
                onTap: () => setState(() => _selectedType = 'client'),
              ),
              const SizedBox(height: AppSpacing.m),
              _AccountTypeCard(
                title: 'Work Provider',
                description: 'I offer professional services',
                icon: Icons.handyman_outlined,
                selected: _selectedType == 'workProvider',
                onTap: () => setState(() => _selectedType = 'workProvider'),
              ),
              const SizedBox(height: AppSpacing.m),
              _AccountTypeCard(
                title: 'Marketplace',
                description: 'I own a local business',
                icon: Icons.storefront_outlined,
                selected: _selectedType == 'marketplace',
                onTap: () => setState(() => _selectedType = 'marketplace'),
              ),
              const Spacer(),
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: state.isLoading || _selectedType == null
                      ? null
                      : continueFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.accentBlue : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.accentBlue),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingSmall),
                  const SizedBox(height: 4),
                  Text(description, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.accentBlue : AppColors.softGray,
            ),
          ],
        ),
      ),
    );
  }
}
