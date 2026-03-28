import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/models/message_model.dart';
import '../../../services/groq_chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final GroqChatService _groqService = GroqChatService();

  List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<MessageModel> get messages => _messages;
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
      "Describe your problem and I'll help you figure out if you can fix it yourself or if you need a professional!";

  ChatProvider() {
    _initializeNewConversation();
  }

  void _initializeNewConversation() {
    _messages = [
      MessageModel(
        role: 'assistant',
        content: _welcomeMessage,
      ),
    ];
    notifyListeners();
  }

  void startNewConversation() {
    _groqService.clearHistory();
    _initializeNewConversation();
    _isLoading = false;
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(MessageModel(role: 'user', content: text));
    _isLoading = true;
    notifyListeners();

    try {
      final reply = await _groqService.sendMessage(text);
      _messages.add(MessageModel(role: 'assistant', content: reply));
    } catch (e) {
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
    // Add user message bubble with the image
    _messages.add(MessageModel(
      role: 'user',
      content: caption ?? '',
      type: MessageType.image,
      imageFile: imageFile,
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final reply = await _groqService.sendImageMessage(imageFile, additionalText: caption);
      _messages.add(MessageModel(role: 'assistant', content: reply));
    } catch (e) {
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
    // Placeholder user bubble while processing
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

      // Update the last user bubble with the transcription
      final idx = _messages.lastIndexWhere((m) => m.role == 'user' && m.type == MessageType.voice);
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
    } catch (e) {
      _messages.add(MessageModel(
        role: 'system',
        content: 'Failed to process voice message. Please try again.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    startNewConversation();
  }
}
