import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Center(child: Text('Please login'));

    final conversationsAsync = ref.watch(conversationsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: conversationsAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            itemCount: snapshot.docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = snapshot.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final lastMessageAt = (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final int unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.errorRed,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  FirebaseFirestore.instance.collection('conversations').doc(doc.id).delete();
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.accentBlue.withOpacity(0.12),
                    child: Text(
                      (data['otherParticipantName'] as String? ?? 'U')[0].toUpperCase(),
                      style: AppTextStyles.headingSmall.copyWith(color: AppColors.accentBlue),
                    ),
                  ),
                  title: Text(
                    data['otherParticipantName'] as String? ?? 'Service Provider',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    data['lastMessage'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeago.format(lastMessageAt, locale: 'en_short'),
                        style: AppTextStyles.caption,
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.accentBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => context.push('/chat/${doc.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 50, color: AppColors.accentBlue),
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Book a service to start chatting with local experts!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Find a Service Provider',
              onPressed: () => context.push('/search-results'),
            ),
          ],
        ),
      ),
    );
  }
}
