import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider(
  (ref) => NotificationService(),
);

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _hasInitialized = false;

  Future<void> initNotifications(String uid) async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        _hasInitialized = false; // Allow retry if denied
        return;
      }

      await _syncToken(uid);
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
        (token) => _saveToken(uid, token),
      );
    } catch (e) {
      // Ignore exception if request is already in progress or unsupported,
      // silently fail to avoid app crash
      _hasInitialized = false; 
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _syncToken(String uid) async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(uid, token);
    }
  }

  Future<void> _saveToken(String uid, String token) {
    return _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
      'lastTokenRefreshAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
