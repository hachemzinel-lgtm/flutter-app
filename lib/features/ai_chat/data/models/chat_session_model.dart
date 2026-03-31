import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_session.dart';

class ChatSessionModel extends ChatSession {
  ChatSessionModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.lastMessagePreview,
    required super.lastMessageTime,
    required super.createdAt,
  });

  factory ChatSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'New Chat',
      lastMessagePreview: data['lastMessagePreview'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'lastMessagePreview': lastMessagePreview,
      'lastMessageTime': lastMessageTime,
      // Only set createdAt if we're creating
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
