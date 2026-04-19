import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/conversations_list_screen.dart';
import '../../chatbot/screens/chatbot_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../search/screens/results_list_screen.dart';
import 'home_map_screen.dart';

/// Top-level container for the signed-in experience.
///
/// Owns the bottom navigation and keeps each tab alive via [IndexedStack],
/// so switching between Explore/Chat/AI/Alerts/Profile preserves scroll
/// position and in-flight state instead of rebuilding from scratch every
/// time — which was the behavior when the old home used [context.push]
/// for every tap.
///
/// Deep-link pushes (e.g. `/chat/:id` from a notification tap) still land
/// on top of this scaffold normally via GoRouter.
class MainScaffold extends ConsumerStatefulWidget {
  /// Index of the tab to select initially. Defaults to 0 (Explore).
  final int initialTab;
  const MainScaffold({super.key, this.initialTab = 0});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  late int _currentIndex = widget.initialTab;

  static const _tabs = <_TabSpec>[
    _TabSpec(icon: Icons.explore, label: 'EXPLORE'),
    _TabSpec(icon: Icons.search, label: 'SEARCH'),
    _TabSpec(icon: Icons.chat_bubble_outline, label: 'CHAT'),
    _TabSpec(icon: Icons.smart_toy, label: 'ASK AI'),
    _TabSpec(
        icon: Icons.notifications_none,
        label: 'ALERTS',
        showBadgeForUnread: true),
    _TabSpec(icon: Icons.person_outline, label: 'PROFILE'),
  ];

  // Pages are built once and kept alive by IndexedStack. Using const where
  // possible so Flutter can skip rebuilds on tab switches.
  static const List<Widget> _pages = <Widget>[
    HomeMapScreen(),
    ResultsListScreen(),
    ConversationsListScreen(),
    ChatbotPage(),
    NotificationsScreen(),
    EditProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Let each inner page own its own AppBar/FAB. The outer body is
      // just an IndexedStack; the bottom nav is the only shared chrome.
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _TabSpec {
  final IconData icon;
  final String label;
  final bool showBadgeForUnread;
  const _TabSpec({
    required this.icon,
    required this.label,
    this.showBadgeForUnread = false,
  });
}

class _BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Unread-count stream drives the ALERTS badge without rebuilding the
    // whole scaffold. Safe to watch here because we're already under
    // ProviderScope.
    final user = ref.watch(authStateProvider).value;
    final unreadAsync = user == null
        ? const AsyncValue<int>.data(0)
        : ref.watch(unreadNotificationCountProvider(user.uid));

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _navItem(
              spec: tabs[i],
              index: i,
              isSelected: currentIndex == i,
              unreadBadge:
                  tabs[i].showBadgeForUnread ? unreadAsync.value ?? 0 : 0,
            ),
        ],
      ),
    );
  }

  Widget _navItem({
    required _TabSpec spec,
    required int index,
    required bool isSelected,
    required int unreadBadge,
  }) {
    final color = isSelected ? AppColors.accentBlue : AppColors.softGray;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(spec.icon, color: color),
                if (unreadBadge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadBadge > 99 ? '99+' : '$unreadBadge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              spec.label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
