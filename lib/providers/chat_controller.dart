import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/views/chat_message.dart';
import 'package:flutter_application_1/services/gemini_chat_service.dart';
import 'package:flutter_application_1/providers/chat_session_provider.dart';

// ─── Service provider ───────────────────────────────────────────────────────

/// Singleton GeminiChatService shared across the app.
final geminiChatServiceProvider = Provider<GeminiChatService>((ref) {
  return GeminiChatService();
});

// ─── State ───────────────────────────────────────────────────────────────────

class ChatState {
  final bool isLoading;
  final String? error;

  const ChatState({this.isLoading = false, this.error});

  ChatState copyWith({bool? isLoading, String? error}) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,            // allow explicit null to clear the error
    );
  }
}

// ─── Controller ──────────────────────────────────────────────────────────────

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  // ── Session management ──────────────────────────────────────────────────

  Future<void> loadSessionContext(String sessionId) async {
    state = state.copyWith(isLoading: true);
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

      ref.read(geminiChatServiceProvider).setHistory(history);
      ref.read(activeChatSessionIdProvider.notifier).setId(sessionId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load session: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> startNewSession() async {
    ref.read(geminiChatServiceProvider).clearHistory();
    ref.read(activeChatSessionIdProvider.notifier).setId(null);
    state = const ChatState();
  }

  // ── Internal helpers ────────────────────────────────────────────────────

  /// Returns (or lazily creates) the active Firestore session ID.
  Future<String> _ensureSession() async {
    var sessionId = ref.read(activeChatSessionIdProvider);
    if (sessionId != null) return sessionId;

    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('User not logged in');

    final session = await ref
        .read(chatSessionRepositoryProvider)
        .createChatSession(user.uid);
    sessionId = session.id;
    ref.read(activeChatSessionIdProvider.notifier).setId(sessionId);
    return sessionId;
  }

  Future<void> _maybeSetTitle(
      String uid,
      String sessionId,
      String titleText,
      ) async {
    final repo = ref.read(chatSessionRepositoryProvider);
    final existing = await repo.getSessionMessages(uid, sessionId);
    if (existing.length <= 1) {
      final title =
      titleText.length > 30 ? '${titleText.substring(0, 27)}…' : titleText;
      await repo.updateSessionTitle(uid, sessionId, title);
    }
  }

  Future<void> _saveMessage(
      String uid,
      String sessionId,
      String content,
      bool isUser,
      ) async {
    final msg = ChatMessage(
      id: '',
      sessionId: sessionId,
      content: content,
      isUserMessage: isUser,
      timestamp: DateTime.now(),
    );
    await ref
        .read(chatSessionRepositoryProvider)
        .saveMessage(uid, sessionId, msg);
  }

  // ── Send text ───────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final sessionId = await _ensureSession();

      await _saveMessage(user.uid, sessionId, text, true);
      await _maybeSetTitle(user.uid, sessionId, text);

      final reply =
      await ref.read(geminiChatServiceProvider).sendMessage(text);

      await _saveMessage(user.uid, sessionId, reply, false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Send image ──────────────────────────────────────────────────────────

  Future<void> sendImageMessage(File imageFile, {String? caption}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final sessionId = await _ensureSession();
      final userText = caption?.isNotEmpty == true ? caption! : '[Image attached]';

      await _saveMessage(user.uid, sessionId, userText, true);
      await _maybeSetTitle(user.uid, sessionId, caption ?? 'Image Issue');

      final reply = await ref
          .read(geminiChatServiceProvider)
          .sendImageMessage(imageFile, additionalText: caption);

      await _saveMessage(user.uid, sessionId, reply, false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Send voice ──────────────────────────────────────────────────────────

  Future<void> sendVoiceMessage(File audioFile) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final sessionId = await _ensureSession();

      // Transcribe + reply in one service call
      final result =
      await ref.read(geminiChatServiceProvider).sendVoiceMessage(audioFile);

      final transcriptLabel =
      result.transcript.isNotEmpty ? '🎤 ${result.transcript}' : '[Voice message]';

      await _saveMessage(user.uid, sessionId, transcriptLabel, true);
      await _maybeSetTitle(
        user.uid,
        sessionId,
        result.transcript.isNotEmpty ? result.transcript : 'Voice Note',
      );

      await _saveMessage(user.uid, sessionId, result.reply, false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);