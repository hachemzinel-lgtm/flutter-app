import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqChatService {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _chatUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _audioUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';

  final List<Map<String, dynamic>> _conversationHistory = [];

  GroqChatService() {
    _conversationHistory.add({
      'role': 'system',
      'content': '''You are a helpful home repair and maintenance assistant called "FixIt AI". 
Users come to you with home problems like plumbing issues, electrical problems, painting, appliance repairs, carpentry, HVAC, and general home maintenance.

Your job is to:
1) Ask clarifying questions to understand the problem better.
2) If it is a simple and safe fix, give them clear step-by-step DIY instructions they can follow safely.
3) If the problem is dangerous (electrical hazards, gas leaks, major plumbing bursts, structural damage), complex, or requires special tools and expertise, clearly tell them they MUST call a professional (plumber, electrician, carpenter, painter, HVAC technician, etc.) and explain WHY it is not safe to DIY.
4) Always prioritize user safety. NEVER suggest DIY for dangerous tasks like electrical panel work, gas line issues, structural problems, or anything involving risk of injury.
5) Be friendly, practical, and concise. Use simple language anyone can understand. Use emojis to make the conversation friendly.
6) When a user describes what they see in a photo, provide specific advice about that visible issue.
7) If asked about something completely unrelated to home repair and maintenance, politely say: "I specialize in home repair and maintenance issues! Tell me about any problem in your house and I will help you figure it out. 🏠🔧"
8) When recommending a professional, mention the TYPE of professional they need (plumber, electrician, etc.) so they can search for one in the app.'''
    });
  }

  Future<String> sendMessage(String userMessage) async {
    _conversationHistory.add({
      'role': 'user',
      'content': userMessage,
    });

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });
        return assistantMessage;
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  Future<String> sendImageMessage(File imageFile, {String? additionalText}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final userContent = [
        {
          'type': 'text',
          'text': additionalText ??
              'I have this home issue. Please look at this photo and tell me what the problem might be, whether I can fix it myself safely, or if I need to call a professional.'
        },
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
        }
      ];

      _conversationHistory.add({
        'role': 'user',
        'content': additionalText ?? '[User sent a photo of their home issue]',
      });

      final messagesWithImage = List<Map<String, dynamic>>.from(
        _conversationHistory.sublist(0, _conversationHistory.length - 1),
      );
      messagesWithImage.add({
        'role': 'user',
        'content': userContent,
      });

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });
        return assistantMessage;
      } else {
        return 'Error analyzing image: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error processing image: $e';
    }
  }

  Future<String> transcribeAudio(File audioFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_audioUrl));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-large-v3';
      request.fields['language'] = 'en';
      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] as String? ?? '';
      } else {
        return 'Error transcribing audio: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error processing audio: $e';
    }
  }

  Future<Map<String, String>> sendVoiceMessage(File audioFile) async {
    final transcription = await transcribeAudio(audioFile);
    if (transcription.startsWith('Error')) {
      return {'transcription': '', 'response': transcription};
    }
    final aiResponse = await sendMessage(transcription);
    return {'transcription': transcription, 'response': aiResponse};
  }

  void clearHistory() {
    _conversationHistory.removeRange(1, _conversationHistory.length);
  }
}
