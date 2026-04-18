import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_chat_service.dart';
import '../repositories/ai_chat_repository.dart';
import '../../../../core/providers/auth_provider.dart';

final aiChatServiceProvider = Provider<AiChatService>((ref) => AiChatService());
final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) => AiChatRepository());

final userSessionsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.watch(aiChatRepositoryProvider).getUserSessions(userId);
});

final sessionMessagesProvider = StreamProvider.family<List<Map<String, dynamic>>, ({String userId, String sessionId})>((ref, arg) {
  return ref.watch(aiChatRepositoryProvider).getSessionMessages(arg.userId, arg.sessionId);
});

class ActiveChatState {
  final String? sessionId;
  final bool isSending;
  final String? error;

  ActiveChatState({this.sessionId, this.isSending = false, this.error});

  ActiveChatState copyWith({String? sessionId, bool? isSending, String? error}) {
    return ActiveChatState(
      sessionId: sessionId ?? this.sessionId,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
    );
  }
}

class ActiveChatController {
  final Ref ref;
  final String? initialSessionId;
  
  final _stateController = StreamController<ActiveChatState>.broadcast();
  late ActiveChatState _currentState;

  ActiveChatController(this.ref, this.initialSessionId) {
    _currentState = ActiveChatState(sessionId: initialSessionId);
    _stateController.add(_currentState);
  }

  Stream<ActiveChatState> get stateStream => _stateController.stream;
  ActiveChatState get currentState => _currentState;

  void _updateState(ActiveChatState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }

  Future<String> startNewSession() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('Must be logged in to chat');

    _updateState(_currentState.copyWith(isSending: true, error: null));
    try {
      final newSessionId = await ref.read(aiChatRepositoryProvider).createSession(user.uid);
      _updateState(_currentState.copyWith(sessionId: newSessionId, isSending: false));
      return newSessionId;
    } catch (e) {
      _updateState(_currentState.copyWith(isSending: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> sendMessage(String text, List<Map<String, dynamic>> history) async {
    final user = ref.read(authStateProvider).value;
    final currentSessionId = _currentState.sessionId;
    
    if (user == null || currentSessionId == null) return;

    _updateState(_currentState.copyWith(isSending: true, error: null));

    try {
      // 1. Add user message to Firestore
      final userMessage = {'role': 'user', 'content': text, 'type': 'text'};
      await ref.read(aiChatRepositoryProvider).addMessage(user.uid, currentSessionId, userMessage);

      // 2. Cast dynamic history to typed list for AiChatService
      final typedHistory = history
          .map((m) => {'role': m['role'] as String? ?? 'user', 'content': m['content'] as String? ?? ''})
          .toList();

      // 3. Get AI Response
      final reply = await ref.read(aiChatServiceProvider).sendMessage(text, typedHistory);

      // 4. Add assistant message to Firestore
      final assistantMessage = {'role': 'assistant', 'content': reply, 'type': 'text'};
      await ref.read(aiChatRepositoryProvider).addMessage(user.uid, currentSessionId, assistantMessage);
      
      _updateState(_currentState.copyWith(isSending: false));
    } catch (e) {
      _updateState(_currentState.copyWith(isSending: false, error: e.toString()));
      rethrow;
    }
  }

  void dispose() {
    _stateController.close();
  }
}

final activeChatControllerProvider = Provider.family<ActiveChatController, String?>((ref, sessionId) {
  final controller = ActiveChatController(ref, sessionId);
  ref.onDispose(() => controller.dispose());
  return controller;
});

final activeChatStateProvider = StreamProvider.family<ActiveChatState, String?>((ref, sessionId) {
  return ref.watch(activeChatControllerProvider(sessionId)).stateStream;
});
