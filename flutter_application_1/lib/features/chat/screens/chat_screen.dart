import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

/// Live stream of the conversation document itself — used to render the
/// other participant's name/status in the AppBar.
final _conversationDocProvider = StreamProvider.family<
    DocumentSnapshot<Map<String, dynamic>>,
    String>((ref, conversationId) {
  return FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .snapshots();
});

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _markedRead = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    // One-shot mark-read per mount; don't re-fire on every rebuild.
    if (!_markedRead) {
      _markedRead = true;
      ref
          .read(chatServiceProvider)
          .markConversationRead(
              conversationId: widget.conversationId, uid: user.uid);
    }

    final conversationAsync =
        ref.watch(_conversationDocProvider(widget.conversationId));
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final chatService = ref.read(chatServiceProvider);

    final currentUser = ChatUser(
      id: user.uid,
      firstName: user.displayName ?? 'Me',
      profileImage: user.photoURL,
    );

    // Resolve the "other" participant from the conversation doc.
    final conversationData = conversationAsync.asData?.value.data();
    final otherId = _otherParticipant(conversationData, user.uid);
    final otherName = _nameFor(conversationData, otherId) ?? 'Chat';
    final otherPhoto = _photoFor(conversationData, otherId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherName, style: AppTextStyles.headingSmall),
            // Online/offline presence not yet tracked — keep neutral.
            Text(
              'Tap to view profile',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.softGray),
            ),
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
            final data = doc.data();
            final senderId = (data['senderId'] as String?) ?? '';
            final senderName = (data['senderName'] as String?) ??
                _nameFor(conversationData, senderId) ??
                'User';
            return ChatMessage(
              user: ChatUser(id: senderId, firstName: senderName),
              text: (data['text'] as String?) ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          }).toList();

          return DashChat(
            currentUser: currentUser,
            onSend: (ChatMessage message) {
              // Fire-and-forget from the UI — errors surface via the
              // messages stream if the write fails.
              chatService.sendMessage(
                conversationId: widget.conversationId,
                senderId: user.uid,
                senderName: user.displayName ?? 'Me',
                text: message.text,
              );
            },
            messages: messages,
            messageOptions: MessageOptions(
              showOtherUsersAvatar: true,
              showTime: true,
              containerColor: AppColors.accentBlue,
              currentUserContainerColor: AppColors.accentBlue,
              onLongPressMessage: (_) {},
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String? _otherParticipant(Map<String, dynamic>? data, String selfUid) {
    if (data == null) return null;
    final ps = List<String>.from(data['participants'] ?? const []);
    return ps.firstWhere(
      (p) => p != selfUid,
      orElse: () => '',
    );
  }

  String? _nameFor(Map<String, dynamic>? data, String? uid) {
    if (data == null || uid == null || uid.isEmpty) return null;
    final names = data['participantNames'];
    if (names is Map) {
      return names[uid] as String?;
    }
    return null;
  }

  String? _photoFor(Map<String, dynamic>? data, String? uid) {
    if (data == null || uid == null || uid.isEmpty) return null;
    final photos = data['participantPhotos'];
    if (photos is Map) {
      return photos[uid] as String?;
    }
    return null;
  }
}
