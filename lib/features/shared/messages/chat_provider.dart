import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final conversationsProvider = StreamProvider.family((ref, String uid) {
  return ref.watch(chatServiceProvider).getConversations(uid);
});

final messagesProvider = StreamProvider.family((ref, String conversationId) {
  return ref.watch(chatServiceProvider).getMessages(conversationId);
});
