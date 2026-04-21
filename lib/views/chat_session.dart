import 'package:flutter_application_1/views/chat_message.dart';

class ChatSession {
  final String id;
  final String userId;
  final String title;
  final String lastMessagePreview;
  final DateTime lastMessageTime;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.lastMessagePreview,
    required this.lastMessageTime,
    required this.createdAt,
    this.messages = const [],
  });

  ChatSession copyWith({
    String? title,
    String? lastMessagePreview,
    DateTime? lastMessageTime,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id,
      userId: userId,
      title: title ?? this.title,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt,
      messages: messages ?? this.messages,
    );
  }
}
