import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/models/user_model.dart';
import '../../../../auth/providers/auth_provider.dart';

class MainScaffoldWrapper extends ConsumerWidget {
  const MainScaffoldWrapper({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(index,
        initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider).value;
    final userType = userDoc?.userType ?? UserType.client;

    final items = _navItems(userType);
    final currentBranchIndex = navigationShell.currentIndex;
    
    // Find matching UI index for current shell index
    int selectedUiIndex = 0;
    for (int i = 0; i < items.length; i++) {
       if (items[i].branchIndex == currentBranchIndex) {
         selectedUiIndex = i;
         break;
       }
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isSelected = selectedUiIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _goBranch(item.branchIndex),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentBlue.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? AppColors.accentBlue
                                  : AppColors.softGray,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.accentBlue
                                  : AppColors.softGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  List<_NavItem> _navItems(UserType type) {
    switch (type) {
      case UserType.client:
        return [
          _NavItem('Home', Icons.home_outlined, Icons.home_rounded, 0),
          _NavItem('Best Providers', Icons.star_outline_rounded, Icons.star_rounded, 1),
          _NavItem('Messages', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 2),
          _NavItem('AI Chat', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 3),
          _NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded, 4),
        ];
      case UserType.workProvider:
        return [
          _NavItem('Home', Icons.home_outlined, Icons.home_rounded, 0),
          _NavItem('Messages', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 2),
          _NavItem('AI Chat', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 3),
          _NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded, 4),
        ];
      case UserType.marketplace:
        return [
          _NavItem('Home', Icons.home_outlined, Icons.home_rounded, 0),
          _NavItem('Messages', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 2),
          _NavItem('AI Chat', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 3),
          _NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded, 4),
        ];
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int branchIndex;
  const _NavItem(this.label, this.icon, this.activeIcon, this.branchIndex);
}
