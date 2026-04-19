import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final conversationsProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, String>(
  (ref, uid) => ref.watch(chatServiceProvider).getConversations(uid),
);

final messagesProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, String>(
  (ref, conversationId) =>
      ref.watch(chatServiceProvider).getMessages(conversationId),
);
