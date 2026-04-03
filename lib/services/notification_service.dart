import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedAppSubscription;

  static Future<void> initialize() async {
    if (_initialized) {
      print('--- [FCM] Initialization skipped because it already ran');
      return;
    }

    final service = NotificationService();
    _initialized = true;
    print('--- [FCM] Starting post-login FCM initialization');

    try {
      final settings = await service._messaging.requestPermission();
      print(
        '--- [FCM] Permission status: ${settings.authorizationStatus.name}',
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print('--- [FCM] Notification permission not granted');
        return;
      }

      final token = await service._messaging.getToken();
      final userId = service._auth.currentUser?.uid;
      print('--- [FCM] Current user: $userId');
      print('--- [FCM] Token fetched: ${token != null && token.isNotEmpty}');

      if (userId != null && token != null) {
        await service._firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = service._messaging.onTokenRefresh.listen((
        newToken,
      ) async {
        final uid = service._auth.currentUser?.uid;
        print('--- [FCM] Token refreshed for user: $uid');
        if (uid == null) {
          return;
        }
        await service._firestore.collection('users').doc(uid).set({
          'fcmToken': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      await _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      await _openedAppSubscription?.cancel();
      _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleBackgroundMessage,
      );

      print('--- [FCM] Post-login initialization complete');
    } catch (error, stackTrace) {
      _initialized = false;
      print('FCM initialization failed: $error');
      print('--- [FCM] Stack trace: $stackTrace');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('--- [FCM] Foreground message received: ${message.messageId}');
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    print('--- [FCM] Notification opened app: ${message.messageId}');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? conversationId,
    String? route,
    Map<String, dynamic>? metadata,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'type': type,
          'conversationId': conversationId,
          'route': route,
          'metadata': metadata ?? <String, dynamic>{},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> markAsRead(String uid, String notificationId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String uid, String notificationId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  String? resolveDeepLink(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      return route;
    }

    final type = data['type']?.toString();
    switch (type) {
      case 'message':
        final conversationId = data['conversationId']?.toString();
        if (conversationId != null && conversationId.isNotEmpty) {
          return '/messages/$conversationId';
        }
        return '/messages';
      case 'review':
        final metadata = data['metadata'] is Map
            ? Map<String, dynamic>.from(data['metadata'] as Map)
            : <String, dynamic>{};
        final profileId = metadata['targetUserId']?.toString();
        if (profileId != null && profileId.isNotEmpty) {
          return '/reviews/$profileId';
        }
        return '/profile';
      case 'verification':
        return '/profile';
      case 'report':
        return '/admin/reports';
      default:
        return '/home';
    }
  }
}
