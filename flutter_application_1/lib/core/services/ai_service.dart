import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  Future<MessageModel?> sendMessage(List<MessageModel> history) async {
    final apiKey = dotenv.env['GOOGLE_GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Error: GOOGLE_GEMINI_API_KEY is missing in .env configurations.');
      return null;
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

      // Merge sequential user messages if they happen to exist consecutively (Gemini requirement)
      final List<Content> compressedHistory = [];
      for (var c in chatHistory) {
        if (compressedHistory.isNotEmpty && compressedHistory.last.role == c.role) {
          compressedHistory.last.parts.addAll(c.parts);
        } else {
          compressedHistory.add(c);
        }
      }

      final response = await model.generateContent(compressedHistory);

      if (response.text != null) {
        return MessageModel(
          role: 'assistant',
          content: response.text!,
        );
      }
    } catch (e) {
      debugPrint('Exception in Gemini AIService: $e');
    }
    return null;
  }
}
