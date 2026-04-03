import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../../../core/models/user_model.dart';

class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final userDoc = ref.watch(currentUserDocProvider).value;

    if (authUser == null || userDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final conversationsAsync = ref.watch(conversationsProvider(authUser.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _EmptyMessagesState(
              userTypeLabel: userDoc.userType.displayName,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider(authUser.uid));
            },
            child: ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final otherName = conversation.otherParticipantName(
                  authUser.uid,
                );
                final otherPhoto = conversation.otherParticipantPhoto(
                  authUser.uid,
                );
                final otherType = conversation.otherParticipantType(
                  authUser.uid,
                );
                final unreadCount = conversation.unreadFor(authUser.uid);

                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    context.push(
                      '/messages/${conversation.id}?otherName=${Uri.encodeComponent(otherName)}',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: unreadCount > 0
                          ? AppColors.accentBlue.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        _ConversationAvatar(
                          name: otherName,
                          photoUrl: otherPhoto,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      otherName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  if (conversation.lastMessageTime != null)
                                    Text(
                                      timeago.format(
                                        conversation.lastMessageTime!,
                                        locale: 'en_short',
                                      ),
                                      style: AppTextStyles.caption,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                otherType?.displayName ?? 'NearWork user',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _messagePreview(conversation),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primaryNavy.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontWeight: unreadCount > 0
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (unreadCount > 0) ...[
                                    const SizedBox(width: AppSpacing.s),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentBlue,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(999),
                                        ),
                                      ),
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : '$unreadCount',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          return Center(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Text(
                'Unable to load conversations right now.\n$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          );
        },
      ),
    );
  }

  String _messagePreview(ConversationSummary conversation) {
    if (conversation.lastMessage.trim().isNotEmpty) {
      return conversation.lastMessage;
    }

    switch (conversation.lastMessageType) {
      case ChatMessageType.photo:
        return 'Photo';
      case ChatMessageType.voice:
        return 'Voice message';
      case ChatMessageType.text:
        return 'No messages yet';
    }
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? NetworkImage(photoUrl!)
          : null,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? null
          : Text(
              (name.isNotEmpty ? name.substring(0, 1) : '?').toUpperCase(),
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.accentBlue,
              ),
            ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState({required this.userTypeLabel});

  final String userTypeLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('No messages yet', style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Your $userTypeLabel conversations will appear here once you connect with someone nearby.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              child: const Text('Explore now'),
            ),
          ],
        ),
      ),
    );
  }
}
