import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/chat_session_provider.dart';
import '../../providers/chat_controller.dart';
import '../../domain/entities/chat_session.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatHistoryPage extends ConsumerWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(userChatSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant History'),
        elevation: 0,
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const _EmptyStateWidget();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userChatSessionsProvider);
            },
            child: ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _ChatSessionItem(session: session);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(chatControllerProvider.notifier).startNewSession();
          context.push('/chat-bot');
        },
        backgroundColor: AppColors.accentBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Chat', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _ChatSessionItem extends ConsumerWidget {
  final ChatSession session;

  const _ChatSessionItem({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Chat?'),
              content: const Text('Are you sure you want to delete this chat session?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        final user = ref.read(authStateProvider).value;
        if (user != null) {
          ref.read(chatSessionRepositoryProvider).deleteChatSession(user.uid, session.id);
        }
      },
      child: GestureDetector(
        onTap: () {
          ref.read(chatControllerProvider.notifier).loadSessionContext(session.id);
          context.push('/chat-bot');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: AppTextStyles.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeago.format(session.lastMessageTime),
                    style: AppTextStyles.caption.copyWith(color: AppColors.softGray),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.lastMessagePreview,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.softGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No previous chats',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softGray),
          ),
        ],
      ),
    );
  }
}
