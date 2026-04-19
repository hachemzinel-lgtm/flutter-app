import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType { text, image, voice, file, system }

extension on ChatMessageType {
  String get wireValue => name;
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Reads ─────────────────────────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> getConversations(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Newest-first messages. The UI can reverse this for DashChat which
  /// prefers newest-at-the-bottom ordering.
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
      String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── Conversation lifecycle ────────────────────────────────────────────
  /// Deterministic conversation id for a pair of users. Prevents the
  /// creation of duplicate 1:1 threads when two clients tap "Chat" at the
  /// same time.
  String oneOnOneConversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Gets an existing 1:1 conversation or creates it if missing. Returns
  /// the conversation id so the caller can navigate to `/chat/:id`.
  Future<String> getOrCreateOneOnOneConversation({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
  }) async {
    final id = oneOnOneConversationId(currentUserId, otherUserId);
    final ref = _firestore.collection('conversations').doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        if (otherUserPhotoUrl != null)
          'participantPhotos': {otherUserId: otherUserPhotoUrl},
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unread': {currentUserId: 0, otherUserId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  // ─── Sending ───────────────────────────────────────────────────────────
  /// Sends a message, bumps `lastMessage*`, and increments unread counters
  /// for every participant except the sender. All in a single batch so the
  /// list screen is always consistent with the thread.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    ChatMessageType type = ChatMessageType.text,
    String? mediaUrl,
  }) async {
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    final convoSnap = await conversationRef.get();
    final participants =
        List<String>.from(convoSnap.data()?['participants'] ?? const []);

    final batch = _firestore.batch();

    final messageRef = conversationRef.collection('messages').doc();
    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type.wireValue,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final preview = _previewFor(type: type, text: text);
    final unreadUpdate = <String, Object?>{};
    for (final p in participants) {
      if (p != senderId) {
        unreadUpdate['unread.$p'] = FieldValue.increment(1);
      }
    }
    // Reset the sender's own unread counter — if they were viewing the
    // thread in another session, this keeps it accurate.
    unreadUpdate['unread.$senderId'] = 0;

    batch.update(conversationRef, {
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      ...unreadUpdate,
    });

    await batch.commit();
  }

  /// Marks every message as read for [uid] in the given conversation.
  /// Called when the user opens a chat thread.
  Future<void> markConversationRead({
    required String conversationId,
    required String uid,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({'unread.$uid': 0}).catchError((_) {
      // If the conversation was just deleted / hasn't been created yet,
      // silently swallow rather than crashing the chat screen.
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────
  String _previewFor({required ChatMessageType type, required String text}) {
    switch (type) {
      case ChatMessageType.image:
        return '📷 Photo';
      case ChatMessageType.voice:
        return '🎤 Voice message';
      case ChatMessageType.file:
        return '📎 Attachment';
      case ChatMessageType.system:
        return text;
      case ChatMessageType.text:
        return text;
    }
  }
}
