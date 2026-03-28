import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/message_model.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final String _systemPrompt = """You are a helpful and friendly AI home service advisor. Your role is to:
1. Help users identify and understand home repair issues
2. Analyze photos/images of problems when provided
3. Determine whether DIY is safe or professional help is needed
4. Provide step-by-step guidance for safe DIY fixes
5. Recommend specific professionals when needed
6. Communicate clearly in the user's language

When analyzing images:
- Identify what you see (broken pipe, electrical issue, etc.)
- Assess severity and safety risks
- State clearly if professional needed (YES or NO)
- If DIY safe: Give 3-5 step solution
- If professional needed: Explain why and what type

When discussing voice messages:
- Transcribe accurately
- Understand the issue being described
- Provide helpful response

Always:
- Be professional but friendly
- Focus on safety
- Be honest about limitations
- Suggest professional help when uncertain
- Avoid medical advice (only home repairs)
- Keep responses concise (under 300 words)

If user asks about something unrelated to home services, politely redirect: 'I'm here to help with home repair issues. Is there something home-related I can help with?'""";

  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<MessageModel> sendMessage(List<MessageModel> history) async {
    // 1. Check Internet Connection
    if (!await _hasInternetConnection()) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final apiKey = dotenv.env['GOOGLE_GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Configuration Error: GOOGLE_GEMINI_API_KEY is missing.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );

      final List<Content> chatHistory = [];
      
      for (var msg in history) {
        if (msg.role == 'system') continue;
        
        final List<Part> parts = [];
        if (msg.content.isNotEmpty) {
          parts.add(TextPart(msg.content));
        } else if (msg.role == 'user' && msg.imageBase64 == null && msg.audioBase64 == null) {
          parts.add(TextPart("[Voice message sent]"));
        }

        if (msg.imageBase64 != null && msg.imageBase64!.isNotEmpty) {
          parts.add(DataPart('image/jpeg', base64Decode(msg.imageBase64!)));
        }
        
        if (msg.audioBase64 != null && msg.audioBase64!.isNotEmpty) {
          parts.add(DataPart('audio/m4a', base64Decode(msg.audioBase64!)));
        }

        final role = msg.role == 'assistant' ? 'model' : 'user';
        if (parts.isNotEmpty) {
          chatHistory.add(Content(role, parts));
        }
      }

      // Merge sequential messages of the same role (Gemini requirement)
      final List<Content> compressedHistory = [];
      for (var c in chatHistory) {
        if (compressedHistory.isNotEmpty && compressedHistory.last.role == c.role) {
          compressedHistory.last.parts.addAll(c.parts);
        } else {
          compressedHistory.add(c);
        }
      }

      // 2. Execute with 30-second timeout
      final response = await model.generateContent(compressedHistory).timeout(
        const Duration(seconds: 30),
      );

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Received empty response from AI.');
      }

      return MessageModel(
        role: 'assistant',
        content: text,
      );

    } on TimeoutException {
      throw Exception('Request took too long. Please try again.');
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini API Error: $e');
      throw Exception('AI Service Error: Please try again in a moment.');
    } catch (e) {
      debugPrint('Unexpected AI Error: $e');
      throw Exception('Unexpected error occurred: ${e.toString()}');
    }
  }
}
