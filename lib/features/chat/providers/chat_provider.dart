import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/services/notification_service.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    notificationService: ref.read(notificationServiceProvider),
  );
});

final conversationsProvider = StreamProvider.family<List<ConversationSummary>, String>((
  ref,
  String uid,
) {
  return ref.watch(chatServiceProvider).getConversations(uid);
});

final conversationProvider = StreamProvider.family<ConversationSummary?, String>((
  ref,
  String conversationId,
) {
  return ref.watch(chatServiceProvider).getConversation(conversationId);
});

final messagesProvider = StreamProvider.family<List<MarketplaceChatMessage>, String>((
  ref,
  String conversationId,
) {
  return ref.watch(chatServiceProvider).getMessages(conversationId);
});
