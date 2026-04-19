import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../screens/notifications_screen.dart';
import 'notification_service.dart';

/// Invisible widget that bootstraps FCM for the signed-in user and tears
/// it down on sign-out.
///
/// Dropped once near the root of the widget tree (inside MaterialApp.router
/// `builder`) so it has both a Riverpod scope and a BuildContext with a
/// GoRouter available for deep-linking on notification tap.
///
/// Behaviour:
///   * On sign-in → calls [NotificationService.initNotifications] with a
///     route-aware tap handler.
///   * On sign-out → calls [NotificationService.tearDown] to drop the
///     device's token so pushes don't follow the user off the device.
///   * Binds only once per uid (the service itself also guards against
///     double-init, belt-and-braces).
class FcmLifecycle extends ConsumerStatefulWidget {
  final Widget child;
  const FcmLifecycle({super.key, required this.child});

  @override
  ConsumerState<FcmLifecycle> createState() => _FcmLifecycleState();
}

class _FcmLifecycleState extends ConsumerState<FcmLifecycle> {
  String? _boundUid;

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      final user = next.value;
      final service = ref.read(notificationServiceProvider);

      if (user == null) {
        if (_boundUid != null) {
          service.tearDown();
          _boundUid = null;
        }
        return;
      }

      if (_boundUid == user.uid) return;
      _boundUid = user.uid;

      service.initNotifications(
        user.uid,
        onMessageTapped: (message) => _routeForMessage(context, message),
      );
    });

    return widget.child;
  }

  void _routeForMessage(BuildContext context, RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final convId = data['conversationId'] as String?;
    final providerId = data['providerId'] as String?;

    if (type == 'message' && convId != null) {
      context.push('/chat/$convId');
      return;
    }
    if (type == 'booking' && providerId != null) {
      context.push('/provider-profile/$providerId');
      return;
    }
    context.push('/notifications');
  }
}
