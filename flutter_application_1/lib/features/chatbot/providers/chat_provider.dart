import 'package:flutter/foundation.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/ai_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ChatProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final String? storedHistory = await _storage.read(key: 'chat_history');
      if (storedHistory != null) {
        final List<dynamic> decoded = jsonDecode(storedHistory);
        _messages = decoded.map((e) => MessageModel.fromJson(e)).toList();
      } else {
        _messages = [
          MessageModel(
            role: 'assistant',
            content: "Hi there! 👋 I'm your AI service advisor. \n\nI can help you with:\n- 🔧 Identifying home repair issues\n- 📸 Analyzing photos of problems\n- 🎤 Recording voice descriptions\n- ✅ Determining if you need professional help\n\nJust describe your problem or send me a photo/voice message and I'll help!",
          )
        ];
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> _saveHistory() async {
    try {
      // Limit to last 50 messages to save space
      final List<MessageModel> messagesToSave = _messages.length > 50 
          ? _messages.sublist(_messages.length - 50) 
          : _messages;
      final encoded = jsonEncode(messagesToSave.map((m) => m.toJson()).toList());
      await _storage.write(key: 'chat_history', value: encoded);
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }

  Future<void> sendMessage(String content, {String? imageBase64, String? audioBase64}) async {
    if (content.isEmpty && imageBase64 == null && audioBase64 == null) return;
    
    final userMessage = MessageModel(
      role: 'user', 
      content: content, 
      imageBase64: imageBase64,
      audioBase64: audioBase64,
    );
    
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();
    
    // Save history immediately after user message per PRD persistence bounds
    await _saveHistory();

    final response = await _aiService.sendMessage(_messages);
    
    _isLoading = false;
    if (response != null) {
      _messages.add(response);
    } else {
      _messages.add(MessageModel(
        role: 'system', 
        content: "Something went wrong. Try again in a moment.",
      ));
    }
    
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _messages.clear();
    await _storage.delete(key: 'chat_history');
    _messages = [
      MessageModel(
        role: 'assistant',
        content: "Hi there! 👋 I'm your AI service advisor. \n\nI can help you with:\n- 🔧 Identifying home repair issues\n- 📸 Analyzing photos of problems\n- 🎤 Recording voice descriptions\n- ✅ Determining if you need professional help\n\nJust describe your problem or send me a photo/voice message and I'll help!",
      )
    ];
    notifyListeners();
  }
}
