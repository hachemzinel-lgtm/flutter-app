import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/models/user_model.dart';

enum ChatMessageType {
  text,
  photo,
  voice;

  static ChatMessageType fromValue(String? value) {
    switch (value) {
      case 'photo':
        return ChatMessageType.photo;
      case 'voice':
        return ChatMessageType.voice;
      default:
        return ChatMessageType.text;
    }
  }

  String get previewLabel {
    switch (this) {
      case ChatMessageType.photo:
        return 'Photo';
      case ChatMessageType.voice:
        return 'Voice message';
      case ChatMessageType.text:
        return '';
    }
  }
}

class ConversationSummary {
  ConversationSummary({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.participantTypes,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
  });

  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final Map<String, UserType> participantTypes;
  final String lastMessage;
  final ChatMessageType lastMessageType;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime? createdAt;

  factory ConversationSummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawTypes = Map<String, dynamic>.from(data['participantTypes'] ?? {});
    final rawUnread = Map<String, dynamic>.from(data['unreadCount'] ?? {});

    return ConversationSummary(
      id: doc.id,
      participants: (data['participants'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      participantNames:
          (data['participantNames'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) => MapEntry(key, value.toString()),
          ),
      participantPhotos:
          (data['participantPhotos'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) => MapEntry(key, value.toString()),
          ),
      participantTypes: rawTypes.map(
        (key, value) =>
            MapEntry(key, UserModel.parseUserType(value.toString())),
      ),
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageType: ChatMessageType.fromValue(
        data['lastMessageType']?.toString(),
      ),
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp? ??
                  data['lastMessageAt'] as Timestamp?)
              ?.toDate(),
      unreadCount: rawUnread.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String otherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (participantId) => participantId != currentUserId,
      orElse: () => '',
    );
  }

  String otherParticipantName(String currentUserId) {
    final otherId = otherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'NearWork user';
  }

  String? otherParticipantPhoto(String currentUserId) {
    final otherId = otherParticipantId(currentUserId);
    final value = participantPhotos[otherId];
    return value == null || value.isEmpty ? null : value;
  }

  UserType? otherParticipantType(String currentUserId) {
    final otherId = otherParticipantId(currentUserId);
    return participantTypes[otherId];
  }

  int unreadFor(String userId) => unreadCount[userId] ?? 0;
}

class MarketplaceChatMessage {
  MarketplaceChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhoto,
    required this.type,
    required this.content,
    required this.mediaUrl,
    required this.timestamp,
    required this.isRead,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderPhoto;
  final ChatMessageType type;
  final String content;
  final String? mediaUrl;
  final DateTime? timestamp;
  final bool isRead;

  factory MarketplaceChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MarketplaceChatMessage(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'NearWork user',
      senderPhoto: data['senderPhoto']?.toString() ?? '',
      type: ChatMessageType.fromValue(data['type']?.toString()),
      content: data['content']?.toString() ?? data['text']?.toString() ?? '',
      mediaUrl: data['mediaURL']?.toString() ?? data['mediaUrl']?.toString(),
      timestamp:
          (data['timestamp'] as Timestamp? ?? data['createdAt'] as Timestamp?)
              ?.toDate(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}
