import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String _selectedType = 'client';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your\nAccount Type',
              style: AppTextStyles.headingLarge.copyWith(fontSize: 32),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'How do you want to use NearWork?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _TypeCard(
              title: 'Client',
              subtitle: 'I WANT TO HIRE',
              icon: Icons.person_outline,
              isSelected: _selectedType == 'client',
              onTap: () => setState(() => _selectedType = 'client'),
            ),
            _TypeCard(
              title: 'Service Provider',
              subtitle: 'I WANT TO WORK',
              icon: Icons.handyman_outlined,
              isSelected: _selectedType == 'provider',
              onTap: () => setState(() => _selectedType = 'provider'),
            ),
            _TypeCard(
              title: 'Merchant',
              subtitle: 'I WANT TO SELL',
              icon: Icons.storefront_outlined,
              isSelected: _selectedType == 'merchant',
              onTap: () => setState(() => _selectedType = 'merchant'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.accentBlue),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      'You can always add more account roles later from your profile settings.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            PrimaryButton(
              text: 'Next',
              onPressed: () => context.push('/signup/$_selectedType'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.cardSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.softGray.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentBlue.withOpacity(0.1) : AppColors.softGray.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.accentBlue : AppColors.softGray,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.l),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: isSelected ? AppColors.accentBlue : AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.accentBlue,
            ),
          ],
        ),
      ),
    );
  }
}
