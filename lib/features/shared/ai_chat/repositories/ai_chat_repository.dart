import 'package:cloud_firestore/cloud_firestore.dart';

class AiChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _sessionsRef(String userId) => 
      _firestore.collection('users').doc(userId).collection('ai_sessions');

  CollectionReference _messagesRef(String userId, String sessionId) => 
      _sessionsRef(userId).doc(sessionId).collection('messages');

  Future<String> createSession(String userId) async {
    final docRef = _sessionsRef(userId).doc();
    final sessionId = docRef.id;

    await docRef.set({
      'sessionId': sessionId,
      'createdAt': FieldValue.serverTimestamp(),
      'title': 'New Diagnosis Session',
      'lastMessage': '',
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    return sessionId;
  }

  Future<void> addMessage(
    String userId, 
    String sessionId, 
    Map<String, dynamic> messageData,
  ) async {
    final batch = _firestore.batch();
    final messageRef = _messagesRef(userId, sessionId).doc();

    final dataToSave = {
      ...messageData,
      'timestamp': FieldValue.serverTimestamp(),
    };

    batch.set(messageRef, dataToSave);

    final sessionRef = _sessionsRef(userId).doc(sessionId);
    final Map<String, dynamic> updateData = {
      'lastMessage': messageData['content'],
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };

    // Auto-update title on first user message
    if (messageData['role'] == 'user') {
      final doc = await sessionRef.get();
      if (doc.exists && (doc.get('title') == 'New Diagnosis Session')) {
        String content = messageData['content'] as String;
        updateData['title'] = content.length > 40 ? '${content.substring(0, 37)}...' : content;
      }
    }

    batch.update(sessionRef, updateData);
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getSessionMessages(String userId, String sessionId) {
    return _messagesRef(userId, sessionId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((sn) => sn.docs.map((d) => d.data() as Map<String, dynamic>).toList());
  }

  Stream<List<Map<String, dynamic>>> getUserSessions(String userId) {
    return _sessionsRef(userId)
        .orderBy('lastUpdatedAt', descending: true)
        .snapshots()
        .map((sn) => sn.docs.map((d) => d.data() as Map<String, dynamic>).toList());
  }

  Future<void> deleteSession(String userId, String sessionId) async {
    final messages = await _messagesRef(userId, sessionId).get();
    final batch = _firestore.batch();
    for (var d in messages.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_sessionsRef(userId).doc(sessionId));
    await batch.commit();
  }
}
