import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

// ---------------------------------------------------------------------------
// Top-rated WP cards provider (simple, scoped to this screen)
// ---------------------------------------------------------------------------

final _topRatedWpProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .where('accountType', isEqualTo: 'work_provider')
      .where('reviewCount', isGreaterThanOrEqualTo: 3)
      .orderBy('reviewCount', descending: true)
      .limit(10)
      .get();
  return snap.docs.map((d) {
    final data = Map<String, dynamic>.from(d.data());
    data['uid'] = d.id;
    return data;
  }).toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  void _showSearchSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.softGray.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("I'm looking for...",
                  style: AppTextStyles.headingSmall.copyWith(color: AppColors.primaryNavy)),
              const SizedBox(height: 16),
              _SearchTypeCard(
                emoji: '🔧',
                title: 'Work Provider',
                subtitle: 'Plumbers, electricians, cleaners & more',
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/search-filter?target=work_provider');
                },
              ),
              const SizedBox(height: 12),
              _SearchTypeCard(
                emoji: '🏪',
                title: 'Marketplace',
                subtitle: 'Materials, tools, spare parts & hardware',
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/search-filter?target=marketplace');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topRated = ref.watch(_topRatedWpProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        title: Text('NearWork',
            style: AppTextStyles.headingMedium.copyWith(color: AppColors.primaryNavy)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primaryNavy),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.electricBlue,
        onRefresh: () async => ref.invalidate(_topRatedWpProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── Search Banner ─────────────────────────────────
            _SearchBannerCard(
              subtitle: 'Find trusted professionals and suppliers near you',
              onSearchTap: () => _showSearchSheet(context, ref),
            ),
            const SizedBox(height: 24),
            // ── Top Rated Near You ────────────────────────────
            Text('Top Rated Near You',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            topRated.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No top-rated providers yet.',
                          style: TextStyle(color: AppColors.softGray)),
                    ),
                  );
                }
                return SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final p = list[i];
                      return _TopRatedCard(provider: p);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.electricBlue)),
              error: (e, _) => Text('Could not load providers: $e',
                  style: const TextStyle(color: AppColors.errorRed)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ClientBottomNav(currentIndex: 0),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav
// ---------------------------------------------------------------------------
class _ClientBottomNav extends ConsumerWidget {
  final int currentIndex;
  const _ClientBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.primaryNavy,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(index: 0, icon: Icons.explore, label: 'Explore', current: currentIndex,
                onTap: () => context.go('/home')),
            _NavItem(index: 1, icon: Icons.search, label: 'Search', current: currentIndex,
                onTap: () => context.push('/search-filter?target=work_provider')),
            _NavItem(index: 2, icon: Icons.chat_bubble_outline, label: 'Chat', current: currentIndex,
                onTap: () => context.push('/messages')),
            _NavItem(index: 3, icon: Icons.smart_toy_outlined, label: 'Ask AI', current: currentIndex,
                onTap: () => context.push('/ai-chat')),
            _NavItem(index: 4, icon: Icons.notifications_none, label: 'Alerts', current: currentIndex,
                onTap: () => context.push('/notifications')),
            _NavItem(index: 5, icon: Icons.person_outline, label: 'Profile', current: currentIndex,
                onTap: () => context.push('/profile')),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int current;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({required this.index, required this.current, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? AppColors.electricBlue : AppColors.softGray, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.softGray,
                fontSize: 9,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------
class _SearchBannerCard extends ConsumerWidget {
  final String subtitle;
  final VoidCallback onSearchTap;
  const _SearchBannerCard({required this.subtitle, required this.onSearchTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingText(uid: uid),
          const SizedBox(height: 4),
          Text(subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.softGray, size: 20),
                  const SizedBox(width: 10),
                  Text('What are you looking for?',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingText extends StatelessWidget {
  final String? uid;
  const _GreetingText({this.uid});

  String get _timeGreeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Text('$_timeGreeting 👋',
          style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryNavy, fontWeight: FontWeight.bold));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (ctx, snap) {
        final name = (snap.data?.data() as Map<String, dynamic>?)?['firstName'] as String?;
        return Text('$_timeGreeting${name != null ? ', $name' : ''} 👋',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold));
      },
    );
  }
}

class _SearchTypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SearchTypeCard({required this.emoji, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryNavy.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.softGray),
          ],
        ),
      ),
    );
  }
}

class _TopRatedCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  const _TopRatedCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final imageUrl = provider['profileImageUrl'] as String? ?? provider['photoUrl'] as String?;
    final name = '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
    final profession = provider['profession'] as String? ?? '';
    final rating = (provider['averageRating'] as num?)?.toDouble() ?? 0.0;
    final uid = provider['uid'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/provider-profile/$uid'),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryNavy,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(height: 8),
            Text(name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
            Text(profession,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: AppColors.softGray)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.authenticGold, size: 14),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
