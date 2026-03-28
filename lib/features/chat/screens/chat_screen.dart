import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Center(child: Text('Please login'));

    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final chatService = ref.read(chatServiceProvider);

    final currentUser = ChatUser(
      id: user.uid,
      firstName: user.displayName ?? 'Me',
      profileImage: user.photoURL,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sterling hardware', style: AppTextStyles.headingSmall),
            Text('Online', style: AppTextStyles.caption.copyWith(color: AppColors.availableGreen)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: messagesAsync.when(
        data: (snapshot) {
          final messages = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ChatMessage(
              user: ChatUser(id: data['senderId'], firstName: data['senderName']),
              text: data['text'],
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();

          return DashChat(
            currentUser: currentUser,
            onSend: (ChatMessage message) {
              chatService.sendMessage(conversationId, {
                'text': message.text,
                'senderId': user.uid,
                'senderName': user.displayName ?? 'Me',
              });
            },
            messages: messages,
            messageOptions: MessageOptions(
              showOtherUsersAvatar: true,
              showTime: true,
              containerColor: AppColors.accentBlue,
              currentUserContainerColor: AppColors.accentBlue,
              onLongPressMessage: (message) {},
            ),
            inputOptions: InputOptions(
              inputDecoration: InputDecoration(
                hintText: 'Type a message...',
                fillColor: AppColors.softGray.withValues(alpha: 0.05),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
