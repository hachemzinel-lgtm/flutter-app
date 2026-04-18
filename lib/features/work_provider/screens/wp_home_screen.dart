import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

// ---------------------------------------------------------------------------
// Recent conversations provider (scoped)
// ---------------------------------------------------------------------------
final _wpRecentConversationsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('conversations')
      .where('participantIds', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .limit(3)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return data;
          }).toList());
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class WpHomeScreen extends ConsumerWidget {
  const WpHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final conversations = ref.watch(_wpRecentConversationsProvider(uid));

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
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── Search Banner ─────────────────────────────────
            _WpSearchBanner(uid: uid),
            const SizedBox(height: 20),

            // ── Your Status ───────────────────────────────────
            _StatusCard(uid: uid),
            const SizedBox(height: 20),

            // ── Recent Conversations ──────────────────────────
            Text('Recent Conversations',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            conversations.when(
              data: (list) {
                if (list.isEmpty) {
                  return _emptyConversations();
                }
                return Column(
                  children: list
                      .map((c) => _ConversationTile(conversation: c, uid: uid))
                      .toList(),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.electricBlue)),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.errorRed)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _WpBottomNav(currentIndex: 0),
    );
  }

  Widget _emptyConversations() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Text('No conversations yet.',
            style: TextStyle(color: AppColors.softGray)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Banner for WP
// ---------------------------------------------------------------------------
class _WpSearchBanner extends ConsumerWidget {
  final String uid;
  const _WpSearchBanner({required this.uid});

  String get _timeGreeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (ctx, snap) {
              final name = (snap.data?.data()
                      as Map<String, dynamic>?)?['firstName'] as String?;
              return Text('$_timeGreeting${name != null ? ', $name' : ''} 👋',
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primaryNavy, fontWeight: FontWeight.bold));
            },
          ),
          const SizedBox(height: 4),
          Text('Find materials, tools and equipment near you',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/search-filter?target=marketplace'),
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
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.softGray)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status / Availability Card
// ---------------------------------------------------------------------------
class _StatusCard extends ConsumerStatefulWidget {
  final String uid;
  const _StatusCard({required this.uid});

  @override
  ConsumerState<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends ConsumerState<_StatusCard> {
  bool _isAvailable = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    if (mounted) {
      setState(() {
        _isAvailable = (doc.data()?['isAvailable'] as bool?) ?? false;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _isAvailable = value);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .update({'isAvailable': value});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: _loading
          ? const Center(child: SizedBox(height: 24, width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricBlue)))
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available for work',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isAvailable
                              ? AppColors.availableGreen.withValues(alpha: 0.12)
                              : AppColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isAvailable ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: _isAvailable ? AppColors.availableGreen : AppColors.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: _toggle,
                  activeTrackColor: AppColors.availableGreen,
                  activeThumbColor: AppColors.white,
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation tile
// ---------------------------------------------------------------------------
class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final String uid;
  const _ConversationTile({required this.conversation, required this.uid});

  @override
  Widget build(BuildContext context) {
    final lastMsg = conversation['lastMessage'] as String? ?? '';
    final id = conversation['id'] as String? ?? '';
    final participants = (conversation['participantIds'] as List<dynamic>?)
            ?.cast<String>() ?? [];
    final otherId = participants.firstWhere((p) => p != uid, orElse: () => '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryNavy,
          child: Text(otherId.isNotEmpty ? otherId[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text('Conversation', style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
        subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption),
        trailing: const Icon(Icons.chevron_right, color: AppColors.softGray),
        onTap: () => context.push('/chat/$id'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav
// ---------------------------------------------------------------------------
class _WpBottomNav extends ConsumerWidget {
  final int currentIndex;
  const _WpBottomNav({required this.currentIndex});

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
            _NavItem(0, Icons.explore, 'Explore', currentIndex,
                () => context.go('/wp-home')),
            _NavItem(1, Icons.search, 'Search MP', currentIndex,
                () => context.push('/search-filter?target=marketplace')),
            _NavItem(2, Icons.chat_bubble_outline, 'Chat', currentIndex,
                () => context.push('/messages')),
            _NavItem(3, Icons.smart_toy_outlined, 'Ask AI', currentIndex,
                () => context.push('/ai-chat')),
            _NavItem(4, Icons.notifications_none, 'Alerts', currentIndex,
                () => context.push('/notifications')),
            _NavItem(5, Icons.person_outline, 'Profile', currentIndex,
                () => context.push('/wp-profile')),
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
  const _NavItem(this.index, this.icon, this.label, this.current, this.onTap);

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
