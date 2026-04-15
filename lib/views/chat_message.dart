class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.isUserMessage,
    required this.timestamp,
  });
}
