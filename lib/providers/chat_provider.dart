import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/services/services_notification_service.dart';
import 'package:flutter_application_1/models/chat_models.dart';
import 'package:flutter_application_1/services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    notificationService: ref.read(notificationServiceProvider),
  );
});

final conversationsProvider =
    StreamProvider.family<List<ConversationSummary>, String>((ref, String uid) {
      final stream = ref.watch(chatServiceProvider).getConversations(uid);
      return (() async* {
        try {
          await for (final conversations in stream) {
            yield conversations;
          }
        } catch (error, stackTrace) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      })();
    });

final conversationProvider = StreamProvider.family<
  ConversationSummary?,
  String
>((ref, String conversationId) {
  final stream = ref.watch(chatServiceProvider).getConversation(conversationId);
  return (() async* {
    try {
      await for (final conversation in stream) {
        yield conversation;
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  })();
});

final messagesProvider =
    StreamProvider.family<List<MarketplaceChatMessage>, String>((
      ref,
      String conversationId,
    ) {
      final stream = ref.watch(chatServiceProvider).getMessages(conversationId);
      return (() async* {
        try {
          await for (final messages in stream) {
            yield messages;
          }
        } catch (error, stackTrace) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      })();
    });
