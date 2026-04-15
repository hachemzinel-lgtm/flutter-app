import 'package:flutter_application_1/views/chat_session.dart';
import 'package:flutter_application_1/views/chat_message.dart';

abstract class ChatSessionRepository {
  Stream<List<ChatSession>> getUserChatSessions(String userId);
  Future<ChatSession> createChatSession(String userId);
  Future<void> saveMessage(
    String userId,
    String sessionId,
    ChatMessage message,
  );
  Future<List<ChatMessage>> getSessionMessages(String userId, String sessionId);
  Stream<List<ChatMessage>> watchSessionMessages(
    String userId,
    String sessionId,
  );
  Future<void> updateSessionTitle(
    String userId,
    String sessionId,
    String newTitle,
  );
  Future<void> deleteChatSession(String userId, String sessionId);
}
