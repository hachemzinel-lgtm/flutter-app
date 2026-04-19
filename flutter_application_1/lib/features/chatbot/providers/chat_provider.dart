import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/models/message_model.dart';
import '../../../services/groq_chat_service.dart';

/// State holder for the FixIt AI (chatbot) screen.
///
/// Seeds a welcome message in its constructor — the screen does not need to
/// (and should not) call [startNewConversation] on mount, because that wipes
/// and re-seeds the list for no reason and causes a visible flicker.
class ChatProvider extends ChangeNotifier {
  ChatProvider() {
    _seedWelcome();
  }

  final GroqChatService _groqService = GroqChatService();

  final List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  static const String _welcomeMessage =
      "Hi there! 👋 I'm FixIt AI, your home repair assistant!\n\n"
      "I can help you with:\n"
      "🔧 Plumbing issues (leaks, clogged drains, toilet problems)\n"
      "⚡ Electrical problems (outlets, switches, lighting)\n"
      "🎨 Painting and wall repairs\n"
      "🪚 Carpentry and furniture fixes\n"
      "🏠 General home maintenance tips\n\n"
      "You can type, send a photo 📷, or record a voice message 🎤\n\n"
      "Describe your problem and I'll help you figure out if you can fix it "
      "yourself or if you need a professional!";

  void _seedWelcome() {
    _messages
      ..clear()
      ..add(MessageModel(role: 'assistant', content: _welcomeMessage));
  }

  /// Resets the visible transcript AND the server-side history. Called from
  /// the "new conversation" app-bar action.
  void startNewConversation() {
    _groqService.clearHistory();
    _seedWelcome();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(MessageModel(role: 'user', content: trimmed));
    _isLoading = true;
    notifyListeners();

    try {
      final reply = await _groqService.sendMessage(trimmed);
      _messages.add(MessageModel(role: 'assistant', content: reply));
    } on GroqApiException catch (e) {
      _messages.add(MessageModel(role: 'system', content: e.message));
    } catch (_) {
      _messages.add(MessageModel(
        role: 'system',
        content: 'Something went wrong. Please try again.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendImageMessage(File imageFile, {String? caption}) async {
    _messages.add(MessageModel(
      role: 'user',
      content: caption ?? '',
      type: MessageType.image,
      imageFile: imageFile,
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final reply =
          await _groqService.sendImageMessage(imageFile, additionalText: caption);
      _messages.add(MessageModel(role: 'assistant', content: reply));
    } on GroqApiException catch (e) {
      _messages.add(MessageModel(role: 'system', content: e.message));
    } catch (_) {
      _messages.add(MessageModel(
        role: 'system',
        content: 'Failed to analyze the image. Please try again.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendVoiceMessage(File audioFile) async {
    _messages.add(MessageModel(
      role: 'user',
      content: '🎤 Voice message',
      type: MessageType.voice,
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _groqService.sendVoiceMessage(audioFile);
      final transcription = result['transcription'] ?? '';
      final reply = result['response'] ?? '';

      // Update the last user bubble with the transcription so users see
      // what the model heard.
      final idx = _messages.lastIndexWhere(
          (m) => m.role == 'user' && m.type == MessageType.voice);
      if (idx != -1) {
        _messages[idx] = MessageModel(
          role: 'user',
          content: '🎤 Voice message',
          type: MessageType.voice,
          transcription: transcription,
          timestamp: _messages[idx].timestamp,
        );
      }

      _messages.add(MessageModel(role: 'assistant', content: reply));
    } on GroqApiException catch (e) {
      _messages.add(MessageModel(role: 'system', content: e.message));
    } catch (_) {
      _messages.add(MessageModel(
        role: 'system',
        content: 'Failed to process voice message. Please try again.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async => startNewConversation();
}
