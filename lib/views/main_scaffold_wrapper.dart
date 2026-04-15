import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';

class MainScaffoldWrapper extends ConsumerWidget {
  const MainScaffoldWrapper({
    required this.child,
    required this.location,
    super.key,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider).value;
    final userType = userDoc?.userType ?? UserType.client;
    final items = _navItems(userType);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: items.map((item) {
                final isSelected = _matches(location, item.path);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(item.path),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
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
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  bool _matches(String currentLocation, String path) {
    if (path == AppRoutes.messages) {
      return currentLocation == AppRoutes.messages ||
          currentLocation.startsWith('${AppRoutes.messages}/');
    }
    return currentLocation == path;
  }

  List<_NavItem> _navItems(UserType type) {
    switch (type) {
      case UserType.client:
        return const [
          _NavItem(
            'Home',
            Icons.home_outlined,
            Icons.home,
            AppRoutes.clientHome,
          ),
          _NavItem('Search', Icons.search, Icons.search, '/search'),
          _NavItem(
            'AI Chat',
            Icons.auto_awesome_outlined,
            Icons.auto_awesome,
            AppRoutes.aiChat,
          ),
          _NavItem(
            'Top Rated',
            Icons.emoji_events_outlined,
            Icons.emoji_events,
            '/top-rated',
          ),
          _NavItem(
            'Profile',
            Icons.person_outline_rounded,
            Icons.person_rounded,
            AppRoutes.profile,
          ),
        ];
      case UserType.workProvider:
        return const [
          _NavItem(
            'Home',
            Icons.home_outlined,
            Icons.home,
            AppRoutes.providerHome,
          ),
          _NavItem('Search', Icons.search, Icons.search, '/search'),
          _NavItem(
            'AI Chat',
            Icons.auto_awesome_outlined,
            Icons.auto_awesome,
            AppRoutes.aiChat,
          ),
          _NavItem(
            'Profile',
            Icons.person_outline_rounded,
            Icons.person_rounded,
            AppRoutes.profile,
          ),
        ];
      case UserType.marketplace:
        return const [
          _NavItem(
            'Home',
            Icons.home_outlined,
            Icons.home,
            AppRoutes.marketplaceHome,
          ),
          _NavItem('Search', Icons.search, Icons.search, '/search'),
          _NavItem(
            'AI Chat',
            Icons.auto_awesome_outlined,
            Icons.auto_awesome,
            AppRoutes.aiChat,
          ),
          _NavItem(
            'Top Rated',
            Icons.emoji_events_outlined,
            Icons.emoji_events,
            '/top-rated',
          ),
          _NavItem(
            'Profile',
            Icons.person_outline_rounded,
            Icons.person_rounded,
            AppRoutes.profile,
          ),
        ];
    }
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon, this.path);

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}
