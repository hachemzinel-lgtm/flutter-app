import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Cloud Messaging for NearWork.
///
/// Responsibilities:
///   1. Ask for notification permission (iOS + Android 13+) on sign-in.
///   2. Cache the FCM token on the user's Firestore doc, and keep it in
///      sync on rotation (`onTokenRefresh`).
///   3. Mirror incoming data-messages into `users/{uid}/notifications` so
///      the in-app Notifications list reflects them even if the system
///      banner was dismissed.
///   4. Expose streams for the Notifications list + unread badge.
///   5. Offer `tearDown()` for sign-out so tokens don't linger on a
///      shared device.
class NotificationService {
  NotificationService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  String? _boundUid;

  /// True once [initNotifications] has completed a permission + token
  /// dance for the current user — guards against double-init from
  /// auth-state rebuilds.
  bool _initialized = false;

  /// Bootstraps FCM for [uid]. Idempotent per uid: calling it again with
  /// the same uid is a no-op; calling with a different uid tears down
  /// the previous subscriptions first.
  Future<void> initNotifications(
    String uid, {
    void Function(RemoteMessage message)? onMessageTapped,
  }) async {
    if (_initialized && _boundUid == uid) return;
    if (_initialized && _boundUid != uid) {
      await tearDown();
    }

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) {
      // Still watch for later permission grants via tokenRefresh, but
      // don't block sign-in — user declined.
      debugPrint('FCM permission not granted (${settings.authorizationStatus})');
    }

    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await _persistToken(uid, token);
      }
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }

    // Keep the stored token in sync when Firebase rotates it.
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _fcm.onTokenRefresh.listen(
      (token) => _persistToken(uid, token),
      onError: (e) => debugPrint('FCM token refresh error: $e'),
    );

    // Foreground messages: mirror to Firestore so the in-app list updates.
    // The system does NOT show a banner for foreground messages by default
    // on Android — developers wire flutter_local_notifications for that.
    // We still surface the payload via our Firestore-backed list.
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen(
      (message) => _mirrorToFirestore(uid, message),
      onError: (e) => debugPrint('FCM onMessage error: $e'),
    );

    // Notification-tap from background → foreground: let caller route.
    _openedSub?.cancel();
    if (onMessageTapped != null) {
      _openedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(onMessageTapped);

      // If the app was launched cold from a notification, handle it once.
      final initial = await _fcm.getInitialMessage();
      if (initial != null) onMessageTapped(initial);
    }

    _boundUid = uid;
    _initialized = true;
  }

  /// Clears the FCM token for the current device and cancels subscriptions.
  /// Call this on sign-out to avoid pushes for the previous user.
  Future<void> tearDown() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _openedSub = null;
    final uid = _boundUid;
    _boundUid = null;
    _initialized = false;

    if (uid != null) {
      try {
        final token = await _fcm.getToken();
        if (token != null) {
          // Best-effort: scrub this token from the user's tokens array so
          // the next recipient of this device doesn't get stale pushes.
          await _firestore.collection('users').doc(uid).set({
            'fcmTokens': FieldValue.arrayRemove([token]),
          }, SetOptions(merge: true));
        }
        await _fcm.deleteToken();
      } catch (e) {
        debugPrint('FCM tearDown: $e');
      }
    }
  }

  Future<void> _persistToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        // Single canonical token (for simple backends).
        'fcmToken': token,
        // Array of tokens (for multi-device fan-out).
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM _persistToken failed: $e');
    }
  }

  Future<void> _mirrorToFirestore(String uid, RemoteMessage message) async {
    // Prefer data-only payloads for deep-linking — fall back to notification
    // block if the sender only populated `notification`.
    final data = message.data;
    final notif = message.notification;

    final title = (data['title'] as String?) ?? notif?.title ?? 'Notification';
    final body = (data['body'] as String?) ?? notif?.body ?? '';
    final type = (data['type'] as String?) ?? 'system';

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        if (data['conversationId'] != null)
          'conversationId': data['conversationId'],
        if (data['providerId'] != null) 'providerId': data['providerId'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'fcm',
      });
    } catch (e) {
      debugPrint('FCM _mirrorToFirestore failed: $e');
    }
  }

  // ─── Firestore-backed list / actions (unchanged public API) ───────────

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream of the unread count for a badge indicator.
  Stream<int> unreadCount(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> markAsRead(String uid, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllRead(String uid) async {
    final batch = _firestore.batch();
    final pending = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final d in pending.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    if (pending.docs.isNotEmpty) await batch.commit();
  }
}

/// Top-level background handler required by Firebase Messaging.
///
/// Registered from `main.dart` via
/// `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`.
/// Must be a top-level (or static) function because it runs in its own
/// isolate where the app's normal object graph is not available.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal: the system tray handles user-visible display for
  // background/terminated messages, and we re-mirror to Firestore on next
  // foreground via onMessageOpenedApp / getInitialMessage flows.
  debugPrint('FCM background message: ${message.messageId}');
}
