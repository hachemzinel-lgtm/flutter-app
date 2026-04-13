import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter_application_1/core/models/user_model.dart';
import '../../../features/notifications/services/notification_service.dart';
import '../models/chat_models.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final NotificationService _notificationService;

  static String buildConversationId(String firstUserId, String secondUserId) {
    final participants = [firstUserId, secondUserId]..sort();
    return '${participants.first}_${participants.last}';
  }

  bool isAllowedConversationPair(UserType firstType, UserType secondType) {
    if (firstType == secondType) {
      return false;
    }

    final hasClient =
        firstType == UserType.client || secondType == UserType.client;
    final hasProvider =
        firstType == UserType.workProvider ||
        secondType == UserType.workProvider;
    final hasMarketplace =
        firstType == UserType.marketplace || secondType == UserType.marketplace;

    return (hasClient && hasProvider) ||
        (hasClient && hasMarketplace) ||
        (hasProvider && hasMarketplace);
  }

  Stream<List<ConversationSummary>> getConversations(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ConversationSummary.fromFirestore).toList(),
        );
  }

  Stream<ConversationSummary?> getConversation(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map(
          (doc) => doc.exists ? ConversationSummary.fromFirestore(doc) : null,
        );
  }

  Stream<List<MarketplaceChatMessage>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(MarketplaceChatMessage.fromFirestore).toList(),
        );
  }

  Future<ConversationSummary> getOrCreateConversation({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    if (!isAllowedConversationPair(currentUser.userType, otherUser.userType)) {
      throw Exception(
        'Messaging is only allowed between clients, providers, and marketplaces in supported pairings.',
      );
    }

    final conversationId = buildConversationId(currentUser.id, otherUser.id);
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final snapshot = await conversationRef.get();
    final participants = [currentUser.id, otherUser.id]..sort();

    final payload = {
      'participants': participants,
      'participantNames': {
        currentUser.id: currentUser.name,
        otherUser.id: otherUser.name,
      },
      'participantPhotos': {
        currentUser.id: currentUser.photoUrl ?? '',
        otherUser.id: otherUser.photoUrl ?? '',
      },
      'participantTypes': {
        currentUser.id: currentUser.userType.name,
        otherUser.id: otherUser.userType.name,
      },
      'unreadCount': {currentUser.id: 0, otherUser.id: 0},
      'lastMessage': snapshot.data()?['lastMessage'] ?? '',
      'lastMessageType': snapshot.data()?['lastMessageType'] ?? 'text',
      'lastMessageTime':
          snapshot.data()?['lastMessageTime'] ?? FieldValue.serverTimestamp(),
      'messageCount': snapshot.data()?['messageCount'] ?? 0,
      'createdAt':
          snapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
    };

    await conversationRef.set(payload, SetOptions(merge: true));
    final freshSnapshot = await conversationRef.get();
    return ConversationSummary.fromFirestore(freshSnapshot);
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required UserModel sender,
    required String content,
  }) async {
    await _sendMessage(
      conversationId: conversationId,
      sender: sender,
      type: ChatMessageType.text,
      content: content.trim(),
    );
  }

  Future<void> sendMediaMessage({
    required String conversationId,
    required UserModel sender,
    required File file,
    required ChatMessageType type,
  }) async {
    if (type != ChatMessageType.photo && type != ChatMessageType.voice) {
      throw Exception('Media messages only support photo or voice types.');
    }

    final messagesRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');
    final messageRef = messagesRef.doc();
    final extension = type == ChatMessageType.photo ? 'jpg' : 'aac';
    final storageRef = _storage.ref().child(
      'messages/$conversationId/${messageRef.id}.$extension',
    );

    final upload = await storageRef.putFile(file);
    final mediaUrl = await upload.ref.getDownloadURL();

    await _sendMessage(
      conversationId: conversationId,
      sender: sender,
      type: type,
      content: type.previewLabel,
      mediaUrl: mediaUrl,
      messageId: messageRef.id,
    );
  }

  Future<void> _sendMessage({
    required String conversationId,
    required UserModel sender,
    required ChatMessageType type,
    required String content,
    String? mediaUrl,
    String? messageId,
  }) async {
    if (content.trim().isEmpty && mediaUrl == null) {
      return;
    }

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final messagesRef = conversationRef.collection('messages');
    final resolvedMessageRef = messageId == null
        ? messagesRef.doc()
        : messagesRef.doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final conversationSnapshot = await transaction.get(conversationRef);
      if (!conversationSnapshot.exists) {
        throw Exception('Conversation not found.');
      }

      final conversation = ConversationSummary.fromFirestore(
        conversationSnapshot,
      );
      final recipientId = conversation.otherParticipantId(sender.id);
      if (recipientId.isEmpty) {
        throw Exception('Unable to resolve the other participant.');
      }

      final recipientUnread = conversation.unreadFor(recipientId);
      final messagePayload = {
        'senderId': sender.id,
        'senderName': sender.name,
        'senderPhoto': sender.photoUrl ?? '',
        'content': content.trim(),
        'text': content.trim(),
        'type': type.name,
        'mediaURL': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      transaction.set(resolvedMessageRef, messagePayload);
      transaction.set(conversationRef, {
        'participants': conversation.participants,
        'participantNames': {
          ...conversation.participantNames,
          sender.id: sender.name,
        },
        'participantPhotos': {
          ...conversation.participantPhotos,
          sender.id: sender.photoUrl ?? '',
        },
        'participantTypes': {
          ...conversation.participantTypes.map(
            (key, value) => MapEntry(key, value.name),
          ),
          sender.id: sender.userType.name,
        },
        'lastMessage': content.trim(),
        'lastMessageType': type.name,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
        'unreadCount': {
          ...conversation.unreadCount,
          sender.id: 0,
          recipientId: recipientUnread + 1,
        },
      }, SetOptions(merge: true));
    });

    final conversationSnapshot = await conversationRef.get();
    if (!conversationSnapshot.exists) {
      return;
    }
    final conversation = ConversationSummary.fromFirestore(
      conversationSnapshot,
    );
    final recipientId = conversation.otherParticipantId(sender.id);
    final senderLabel =
        sender.userType == UserType.marketplace && sender.name.trim().isNotEmpty
        ? sender.name
        : sender.name;

    await _notificationService.createNotification(
      userId: recipientId,
      title: senderLabel,
      body: type == ChatMessageType.text ? content.trim() : type.previewLabel,
      type: 'message',
      conversationId: conversationId,
      route:
          '/messages/$conversationId?otherName=${Uri.encodeComponent(sender.name)}',
    );
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    await conversationRef.set({
      'unreadCount': {userId: 0},
    }, SetOptions(merge: true));

    final unreadMessages = await conversationRef
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      final data = doc.data();
      if (data['senderId'] != userId) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }
}
