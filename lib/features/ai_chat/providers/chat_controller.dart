import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

import '../domain/entities/chat_message.dart';
import '../../../services/groq_chat_service.dart';
import 'chat_session_provider.dart';

// Provides the singleton instance of GroqChatService
final groqChatServiceProvider = Provider<GroqChatService>((ref) {
  return GroqChatService();
});

class ChatState {
  final bool isLoading;
  final String? error;

  ChatState({this.isLoading = false, this.error});

  ChatState copyWith({bool? isLoading, String? error}) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState();
  }

  Future<void> loadSessionContext(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final repo = ref.read(chatSessionRepositoryProvider);
      final messages = await repo.getSessionMessages(user.uid, sessionId);

      final history = messages
          .map(
            (m) => {
              'role': m.isUserMessage ? 'user' : 'assistant',
              'content': m.content,
            },
          )
          .toList();

      ref.read(groqChatServiceProvider).setHistory(history);
      ref.read(activeChatSessionIdProvider.notifier).setId(sessionId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load session');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> startNewSession() async {
    ref.read(groqChatServiceProvider).clearHistory();
    ref.read(activeChatSessionIdProvider.notifier).setId(null);
    state = ChatState();
  }

  Future<String> _ensureSession() async {
    var sessionId = ref.read(activeChatSessionIdProvider);
    if (sessionId == null) {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final session = await ref
          .read(chatSessionRepositoryProvider)
          .createChatSession(user.uid);
      sessionId = session.id;
      ref.read(activeChatSessionIdProvider.notifier).setId(sessionId);
    }
    return sessionId;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final sessionId = await _ensureSession();
      final repo = ref.read(chatSessionRepositoryProvider);

      // Save user message to Firestore
      final userMsg = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: text,
        isUserMessage: true,
        timestamp: DateTime.now(),
      );
      await repo.saveMessage(user.uid, sessionId, userMsg);

      // Update session title if it's the first message
      final messages = await repo.getSessionMessages(user.uid, sessionId);
      if (messages.length <= 1) {
        // 1 is the userMsg we just added
        final title = text.length > 30 ? '${text.substring(0, 27)}...' : text;
        await repo.updateSessionTitle(user.uid, sessionId, title);
      }

      // Call API
      final groq = ref.read(groqChatServiceProvider);
      final reply = await groq.sendMessage(text);

      // Save AI message
      final aiMsg = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: reply,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      await repo.saveMessage(user.uid, sessionId, aiMsg);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendImageMessage(File imageFile, {String? caption}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final sessionId = await _ensureSession();
      final repo = ref.read(chatSessionRepositoryProvider);

      final userText = caption ?? '[Image attached]';
      final userMsg = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: userText,
        isUserMessage: true,
        timestamp: DateTime.now(),
      );
      await repo.saveMessage(user.uid, sessionId, userMsg);

      final messages = await repo.getSessionMessages(user.uid, sessionId);
      if (messages.length <= 1) {
        await repo.updateSessionTitle(user.uid, sessionId, 'Image Issue');
      }

      final groq = ref.read(groqChatServiceProvider);
      final reply = await groq.sendImageMessage(
        imageFile,
        additionalText: caption,
      );

      final aiMsg = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: reply,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      await repo.saveMessage(user.uid, sessionId, aiMsg);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendVoiceMessage(File audioFile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final sessionId = await _ensureSession();
      final repo = ref.read(chatSessionRepositoryProvider);

      final groq = ref.read(groqChatServiceProvider);

      // Step 1: Transcribe audio
      final transcription = await groq.transcribeAudio(audioFile);
      if (transcription.startsWith('Error')) throw Exception(transcription);

      // Save user transcription
      final userMsg = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: transcription.isEmpty
            ? '[Voice message]'
            : '🎤 $transcription',
        isUserMessage: true,
        timestamp: DateTime.now(),
      );
      await repo.saveMessage(user.uid, sessionId, userMsg);

      final messages = await repo.getSessionMessages(user.uid, sessionId);
      if (messages.length <= 1) {
        final title = transcription.isNotEmpty && transcription.length > 25
            ? '${transcription.substring(0, 25)}...'
            : 'Voice Note';
        await repo.updateSessionTitle(user.uid, sessionId, title);
      }

      // Step 2: Get AI reply
      final reply = await groq.sendMessage(transcription);

      final aiMsg = ChatMessage(
        id: '',
        sessionId: sessionId,
        content: reply,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      await repo.saveMessage(user.uid, sessionId, aiMsg);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  () => ChatController(),
);
