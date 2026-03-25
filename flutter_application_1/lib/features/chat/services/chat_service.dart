import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getConversations(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(String conversationId, Map<String, dynamic> messageData) async {
    final batch = _firestore.batch();
    
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();
    
    batch.set(messageRef, {
      ...messageData,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(_firestore.collection('conversations').doc(conversationId), {
      'lastMessage': messageData['text'],
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
