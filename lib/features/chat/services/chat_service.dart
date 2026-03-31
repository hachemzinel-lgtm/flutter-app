import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Future<String> getOrCreateConversation(String currentUid, String currentName, String otherUid, String otherName) async {
    // Check if conversation already exists
    final existing = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUid)
        .get();
    
    for (var doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUid)) {
        return doc.id;
      }
    }

    // Create new one if not
    final ref = _firestore.collection('conversations').doc();
    await ref.set({
      'participants': [currentUid, otherUid],
      'participantNames': {
        currentUid: currentName,
        otherUid: otherName,
      },
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
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

  Future<void> sendMediaMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required File file,
    required String type, // 'photo' | 'voice'
  }) async {
    // 1. Upload to Storage
    final extension = type == 'photo' ? 'jpg' : 'aac';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'messages/$conversationId/$fileName';
    
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final uploadTask = await storageRef.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // 2. Send message with media URL
    await sendMessage(conversationId, {
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'mediaURL': downloadUrl,
      'text': type == 'photo' ? '📷 Photo' : '🎤 Voice message',
    });
  }
}
