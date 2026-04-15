import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/routes/route_paths.dart';
import 'package:flutter_application_1/views/app_colors.dart';
import 'package:flutter_application_1/views/app_text_styles.dart';

class RoleAwareScaffold extends ConsumerWidget {
  const RoleAwareScaffold({
    required this.child,
    required this.location,
    super.key,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider).value;
    final normalizedAccountType = AppRoutes.normalizeAccountType(
      userData?['accountType']?.toString(),
    );
    final items = _navItems(normalizedAccountType);

    return Scaffold(
      body: child,
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
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
                          onTap: () => context.goNamed(item.name),
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
                                      ? AppColors.accentBlue.withValues(
                                          alpha: 0.12,
                                        )
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

  List<_NavItem> _navItems(String? accountType) {
    switch (accountType) {
      case 'workProvider':
      case 'marketplace':
        return const [
          _NavItem(
            'Home',
            Icons.home_outlined,
            Icons.home,
            AppRoutes.home,
            AppRoutes.homeName,
          ),
          _NavItem(
            'Messages',
            Icons.chat_bubble_outline_rounded,
            Icons.chat_bubble_rounded,
            AppRoutes.messages,
            AppRoutes.messagesName,
          ),
          _NavItem(
            'Profile',
            Icons.person_outline_rounded,
            Icons.person_rounded,
            AppRoutes.profile,
            AppRoutes.profileName,
          ),
        ];
      case 'client':
      default:
        return const [
          _NavItem(
            'Home',
            Icons.home_outlined,
            Icons.home,
            AppRoutes.home,
            AppRoutes.homeName,
          ),
          _NavItem(
            'Search',
            Icons.search_rounded,
            Icons.search_rounded,
            AppRoutes.search,
            AppRoutes.searchName,
          ),
          _NavItem(
            'AI Chat',
            Icons.auto_awesome_outlined,
            Icons.auto_awesome,
            AppRoutes.aiChat,
            AppRoutes.aiChatName,
          ),
          _NavItem(
            'Messages',
            Icons.chat_bubble_outline_rounded,
            Icons.chat_bubble_rounded,
            AppRoutes.messages,
            AppRoutes.messagesName,
          ),
          _NavItem(
            'Profile',
            Icons.person_outline_rounded,
            Icons.person_rounded,
            AppRoutes.profile,
            AppRoutes.profileName,
          ),
        ];
    }
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon, this.path, this.name);

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  final String name;
}
