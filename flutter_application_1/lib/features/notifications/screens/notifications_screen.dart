import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

// StreamProvider scoped inside build via ref.watch — defined here for clarity
final _notificationsStreamFamily = StreamProvider.family<QuerySnapshot, String>(
  (ref, uid) => ref.watch(notificationServiceProvider).getNotifications(uid),
);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Center(child: Text('Please login'));

    final notificationsAsync = ref.watch(_notificationsStreamFamily(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) return _buildEmptyState(context);

          final docs = snapshot.docs;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_notificationsStreamFamily(user.uid));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                // Section headers by date
                final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                final showHeader = index == 0 || !_isSameDay(date,
                  (docs[index - 1].data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime.now());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 4),
                        child: Text(
                          _dateHeader(date),
                          style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.softGray),
                        ),
                      ),
                    _buildTile(context, doc.id, data, user.uid, ref),
                  ],
                );
              },
            ),
          );
        },
        loading: () => _buildSkeleton(),
        error: (e, _) => _buildEmptyState(context), // show empty state on error too
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline;
      case 'booking': return Icons.calendar_today_outlined;
      case 'promo': return Icons.local_offer_outlined;
      case 'system': return Icons.verified_outlined;
      default: return Icons.notifications_none;
    }
  }

  Widget _buildTile(BuildContext context, String id, Map<String, dynamic> data, String uid, WidgetRef ref) {
    final bool isRead = data['isRead'] as bool? ?? false;
    final String type = data['type'] as String? ?? 'system';
    final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorRed,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('notifications').doc(id)
            .delete();
      },
      child: InkWell(
        onTap: () {
          ref.read(notificationServiceProvider).markAsRead(uid, id);
          if (type == 'message' && data['conversationId'] != null) {
            context.push('/chat/${data['conversationId']}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
          color: isRead ? null : AppColors.accentBlue.withOpacity(0.03),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isRead ? AppColors.softGray.withOpacity(0.08) : AppColors.accentBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(type),
                  color: isRead ? AppColors.softGray : AppColors.accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] as String? ?? 'Notification',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(data['body'] as String? ?? '', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(timeago.format(date, locale: 'en_short'), style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(color: AppColors.accentBlue, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_none_rounded, size: 50, color: AppColors.accentBlue),
            ),
            const SizedBox(height: 24),
            const Text('No Notifications Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "You'll see booking updates, messages, and offers here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.go('/home'),
                child: const Text('Explore Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 5,
      padding: AppSpacing.pagePadding,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.softGray.withOpacity(0.12), shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 180, decoration: BoxDecoration(color: AppColors.softGray.withOpacity(0.12), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, decoration: BoxDecoration(color: AppColors.softGray.withOpacity(0.08), borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
