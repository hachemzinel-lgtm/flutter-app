import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/entities/chat_session.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/chat_session_repository.dart';
import '../data/repositories/chat_session_repository_impl.dart';

// Repository Provider
final chatSessionRepositoryProvider = Provider<ChatSessionRepository>((ref) {
  return ChatSessionRepositoryImpl();
});

// Stream of Chat Sessions for the current user
final userChatSessionsProvider = StreamProvider.autoDispose<List<ChatSession>>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  final repository = ref.watch(chatSessionRepositoryProvider);
  return repository.getUserChatSessions(user.uid);
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
      final user = ref.watch(authStateProvider).value;
      final sessionId = ref.watch(activeChatSessionIdProvider);

      if (user == null || sessionId == null) return const Stream.empty();

      final repository = ref.watch(chatSessionRepositoryProvider);
      return repository.watchSessionMessages(user.uid, sessionId);
    });
