import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/views/chat_session.dart';
import 'package:flutter_application_1/views/chat_message.dart';
import 'package:flutter_application_1/services/chat_session_repository.dart';
import 'package:flutter_application_1/services/chat_session_repository_impl.dart';

// Repository Provider
final chatSessionRepositoryProvider = Provider<ChatSessionRepository>((ref) {
  return ChatSessionRepositoryImpl();
});

// Stream of Chat Sessions for the current user
final userChatSessionsProvider = StreamProvider.autoDispose<List<ChatSession>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final repository = ref.watch(chatSessionRepositoryProvider);
  final stream = repository.getUserChatSessions(user.uid);
  return (() async* {
    try {
      await for (final sessions in stream) {
        yield sessions;
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  })();
});

class ActiveChatSessionIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setId(String? id) => state = id;
}

final activeChatSessionIdProvider =
    NotifierProvider<ActiveChatSessionIdNotifier, String?>(
      () => ActiveChatSessionIdNotifier(),
    );

// Stream of messages for the currently active session
final activeSessionMessagesProvider =
    StreamProvider.autoDispose<List<ChatMessage>>((ref) {
      final user = ref.watch(currentUserProvider);
      final sessionId = ref.watch(activeChatSessionIdProvider);

      if (user == null || sessionId == null) return const Stream.empty();

      final repository = ref.watch(chatSessionRepositoryProvider);
      final stream = repository.watchSessionMessages(user.uid, sessionId);
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
