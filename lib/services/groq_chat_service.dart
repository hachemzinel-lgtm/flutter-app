import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqChatService {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _chatUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _audioUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _systemPrompt = '''
You are "NearWork Assistant", a friendly troubleshooting assistant for people who are trying to understand whether their problem needs professional help.

Most users are clients describing a real-life problem at home, in a shop, or with a local service need.

Your job is to:
1) Understand the problem first. Ask up to 2 short clarifying questions only when needed.
2) Decide whether the user can safely try simple steps on their own or whether they should contact a professional.
3) If the problem does NOT need professional help right now, clearly say that it sounds safe to try a simple solution first, then give practical, step-by-step help.
4) If the problem DOES need professional help, clearly say: "You should contact a professional." Then name the professional type they need and explain the safety or complexity reason.
5) If there is immediate danger (electric shock risk, gas leak, fire hazard, flooding, structural damage, or severe injury risk), tell the user to stop, stay safe, and contact emergency or qualified professional help immediately.
6) Be warm, calm, supportive, and easy to understand. Sound like a helpful person, not a robot.
7) When you give DIY help, include:
   - what to check first
   - safe steps to try
   - basic tools or materials if needed
   - when to stop and get professional help
8) If the topic is unrelated to practical local-service or repair guidance, politely say you specialize in helping users decide whether they need local professional help and what safe steps they can try first.
9) When replying about an image, focus only on what can reasonably be inferred from the visible issue and mention uncertainty when needed.

Important routing rule for the app:
- Only recommend a professional when it is genuinely needed.
- If a professional is not needed yet, do not push the user toward hiring someone. Help them solve it themselves safely first.

When recommending a professional, naturally mention one category from this list if relevant:
Plumbing, Electrical, Cleaning, Painting, Carpentry, HVAC, Landscaping.
''';

  final List<Map<String, dynamic>> _conversationHistory = [];

  GroqChatService() {
    _conversationHistory.add({
      'role': 'system',
      'content': _systemPrompt,
    });
  }

  Future<String> sendMessage(String userMessage) async {
    _ensureConfigured();
    _conversationHistory.add({'role': 'user', 'content': userMessage});

    try {
      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': _conversationHistory,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode != 200) {
        _removeLastUserMessage();
        throw Exception(_buildApiError(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final assistantMessage =
          data['choices'][0]['message']['content'] as String? ??
          'I could not generate a response right now.';
      _conversationHistory.add({
        'role': 'assistant',
        'content': assistantMessage,
      });
      return assistantMessage;
    } catch (error) {
      _removeLastUserMessage();
      throw Exception(_friendlyErrorMessage(error));
    }
  }

  Future<String> sendImageMessage(
    File imageFile, {
    String? additionalText,
  }) async {
    _ensureConfigured();
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final userContent = [
        {
          'type': 'text',
          'text':
              additionalText ??
              'Please look at this issue and tell me whether I can safely handle it myself first or whether I should contact a professional.',
        },
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
        },
      ];

      _conversationHistory.add({
        'role': 'user',
        'content': additionalText ?? '[User sent a photo of the issue]',
      });

      final messagesWithImage = List<Map<String, dynamic>>.from(
        _conversationHistory.sublist(0, _conversationHistory.length - 1),
      );
      messagesWithImage.add({'role': 'user', 'content': userContent});

      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
          'messages': messagesWithImage,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode != 200) {
        _removeLastUserMessage();
        throw Exception(_buildApiError(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final assistantMessage =
          data['choices'][0]['message']['content'] as String? ??
          'I could not analyze that image right now.';
      _conversationHistory.add({
        'role': 'assistant',
        'content': assistantMessage,
      });
      return assistantMessage;
    } catch (error) {
      _removeLastUserMessage();
      throw Exception(_friendlyErrorMessage(error));
    }
  }

  Future<String> transcribeAudio(File audioFile) async {
    _ensureConfigured();
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_audioUrl));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-large-v3';
      request.fields['language'] = 'en';
      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Audio transcription failed. Please try again.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['text'] as String? ?? '';
    } catch (error) {
      throw Exception(_friendlyErrorMessage(error));
    }
  }

  Future<Map<String, String>> sendVoiceMessage(File audioFile) async {
    final transcription = await transcribeAudio(audioFile);
    final aiResponse = await sendMessage(transcription);
    return {'transcription': transcription, 'response': aiResponse};
  }

  void clearHistory() {
    if (_conversationHistory.length > 1) {
      _conversationHistory.removeRange(1, _conversationHistory.length);
    }
  }

  void setHistory(List<Map<String, dynamic>> pastMessages) {
    clearHistory();
    _conversationHistory.addAll(pastMessages);
  }

  void _ensureConfigured() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'The AI assistant is not configured right now. Please try again later.',
      );
    }
  }

  void _removeLastUserMessage() {
    if (_conversationHistory.length <= 1) {
      return;
    }

    final lastMessage = _conversationHistory.last;
    if (lastMessage['role'] == 'user') {
      _conversationHistory.removeLast();
    }
  }

  String _buildApiError(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'The AI assistant could not be authorized. Please try again later.';
    }
    if (response.statusCode >= 500) {
      return 'The AI assistant is temporarily unavailable. Please try again shortly.';
    }
    return 'The AI assistant could not process this request right now.';
  }

  String _friendlyErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'We could not reach the AI assistant. Please check your connection and try again.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}
