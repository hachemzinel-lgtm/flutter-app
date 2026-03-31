import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/user_model.dart';
import '../providers/selected_account_type_provider.dart';

class AccountTypeScreen extends ConsumerStatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  ConsumerState<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends ConsumerState<AccountTypeScreen>
    with SingleTickerProviderStateMixin {
  UserType _selectedType = UserType.client;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _proceed() {
    // Store selected type for later use in profile setup
    ref.read(selectedAccountTypeProvider.notifier).set(_selectedType);
    switch (_selectedType) {
      case UserType.client:
        context.push('/profile-setup/client');
        break;
      case UserType.workProvider:
        context.push('/profile-setup/provider');
        break;
      case UserType.marketplace:
        context.push('/profile-setup/marketplace');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.l),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentBlue, Color(0xFF0077A8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'How will you use',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.textLight,
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.accentBlue, Color(0xFF7DD3FC)],
                      ).createShader(bounds),
                      child: Text(
                        'NearWork?',
                        style: AppTextStyles.headingLarge.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Select your account type to get started',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Column(
                    children: [
                      _AccountTypeCard(
                        type: UserType.client,
                        title: 'Client',
                        description: 'Looking for services or products',
                        icon: Icons.search_rounded,
                        gradientColors: const [Color(0xFF00B4D8), Color(0xFF0077A8)],
                        isSelected: _selectedType == UserType.client,
                        onTap: () => setState(() => _selectedType = UserType.client),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _AccountTypeCard(
                        type: UserType.workProvider,
                        title: 'Work Provider',
                        description: 'I offer professional services',
                        icon: Icons.handyman_rounded,
                        gradientColors: const [Color(0xFFFFD700), Color(0xFFF59E0B)],
                        isSelected: _selectedType == UserType.workProvider,
                        onTap: () => setState(() => _selectedType = UserType.workProvider),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _AccountTypeCard(
                        type: UserType.marketplace,
                        title: 'Marketplace',
                        description: 'I own a local business',
                        icon: Icons.storefront_rounded,
                        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                        isSelected: _selectedType == UserType.marketplace,
                        onTap: () => setState(() => _selectedType = UserType.marketplace),
                      ),
                    ],
                  ),
                ),
              ),

              // Disclaimer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentBlue.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.accentBlue, size: 18),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Account type cannot be changed after setup.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CTA Button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _proceed,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue as ${_selectedType == UserType.workProvider ? 'Work Provider' : _selectedType.name[0].toUpperCase() + _selectedType.name.substring(1)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
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

class _AccountTypeCard extends StatelessWidget {
  final UserType type;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: isSelected
              ? gradientColors[0].withOpacity(0.08)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? gradientColors[0] : AppColors.softGray.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: isSelected ? gradientColors[0] : AppColors.textDark,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? gradientColors[0] : Colors.transparent,
                border: Border.all(
                  color: isSelected ? gradientColors[0] : AppColors.softGray.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
