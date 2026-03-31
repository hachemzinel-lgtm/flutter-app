import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    required super.id,
    required super.sessionId,
    required super.content,
    required super.isUserMessage,
    required super.timestamp,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      content: data['content'] ?? '',
      isUserMessage: data['isUserMessage'] ?? true,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'content': content,
      'isUserMessage': isUserMessage,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
