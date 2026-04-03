import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_session_repository.dart';
import '../models/chat_session_model.dart';
import '../models/chat_message_model.dart';

class ChatSessionRepositoryImpl implements ChatSessionRepository {
  final FirebaseFirestore _firestore;

  ChatSessionRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<ChatSession>> getUserChatSessions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatSessionModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<ChatSession> createChatSession(String userId) async {
    final sessionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .doc();

    final now = DateTime.now();

    final model = ChatSessionModel(
      id: sessionRef.id,
      userId: userId,
      title: 'New Chat',
      lastMessagePreview: 'Started a new conversation',
      lastMessageTime: now,
      createdAt: now,
    );

    await sessionRef.set(model.toFirestore());

    return model;
  }

  @override
  Future<void> saveMessage(
    String userId,
    String sessionId,
    ChatMessage message,
  ) async {
    final messageRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .doc(message.id.isEmpty ? null : message.id);

    final model = ChatMessageModel(
      id: messageRef.id,
      sessionId: sessionId,
      content: message.content,
      isUserMessage: message.isUserMessage,
      timestamp: message.timestamp,
    );

    await messageRef.set(model.toFirestore());

    // Update parent session
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .doc(sessionId)
        .update({
          'lastMessagePreview': message.content.length > 50
              ? '${message.content.substring(0, 47)}...'
              : message.content,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<List<ChatMessage>> getSessionMessages(
    String userId,
    String sessionId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .toList();
  }

  @override
  Stream<List<ChatMessage>> watchSessionMessages(
    String userId,
    String sessionId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> updateSessionTitle(
    String userId,
    String sessionId,
    String newTitle,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .doc(sessionId)
        .update({'title': newTitle});
  }

  @override
  Future<void> deleteChatSession(String userId, String sessionId) async {
    final sessionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .doc(sessionId);

    // Delete all messages in subcollection first
    final messages = await sessionRef.collection('messages').get();
    final batch = _firestore.batch();

    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete the session document itself
    batch.delete(sessionRef);

    await batch.commit();
  }
}
