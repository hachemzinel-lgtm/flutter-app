import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Raised when the Groq API cannot fulfil a request.
///
/// Carries a user-safe [message] (suitable for surfacing in the UI) and,
/// for debugging, the original [statusCode] and [raw] response body.
class GroqApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? raw;
  GroqApiException(this.message, {this.statusCode, this.raw});
  @override
  String toString() => 'GroqApiException($statusCode): $message';
}

/// Thin client over the Groq OpenAI-compatible endpoints used by FixIt AI.
///
/// Design notes:
/// * Errors are thrown, not returned as magic strings. Callers should
///   `try/catch` and surface a friendly fallback — this keeps bogus
///   `'Error: 401 - ...'` bodies out of the user-visible chat stream.
/// * The user's turn is *not* appended to [_conversationHistory] until we
///   have confirmation the model accepted it. If the call fails we leave
///   history untouched so the next retry sees a clean transcript.
class GroqChatService {
  GroqChatService() {
    _conversationHistory.add({
      'role': 'system',
      'content': _systemPrompt,
    });
  }

  static const String _chatUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _audioUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  static const String _textModel = 'llama-3.1-8b-instant';
  static const String _visionModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';
  static const String _transcriptionModel = 'whisper-large-v3';

  static const String _systemPrompt = '''You are a helpful home repair and maintenance assistant called "FixIt AI".
Users come to you with home problems like plumbing issues, electrical problems, painting, appliance repairs, carpentry, HVAC, and general home maintenance.

Your job is to:
1) Ask clarifying questions to understand the problem better.
2) If it is a simple and safe fix, give them clear step-by-step DIY instructions they can follow safely.
3) If the problem is dangerous (electrical hazards, gas leaks, major plumbing bursts, structural damage), complex, or requires special tools and expertise, clearly tell them they MUST call a professional (plumber, electrician, carpenter, painter, HVAC technician, etc.) and explain WHY it is not safe to DIY.
4) Always prioritize user safety. NEVER suggest DIY for dangerous tasks like electrical panel work, gas line issues, structural problems, or anything involving risk of injury.
5) Be friendly, practical, and concise. Use simple language anyone can understand. Use emojis to make the conversation friendly.
6) When a user describes what they see in a photo, provide specific advice about that visible issue.
7) If asked about something completely unrelated to home repair and maintenance, politely say: "I specialize in home repair and maintenance issues! Tell me about any problem in your house and I will help you figure it out. 🏠🔧"
8) When recommending a professional, mention the TYPE of professional they need (plumber, electrician, etc.) so they can search for one in the app.''';

  final List<Map<String, dynamic>> _conversationHistory = [];

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// Sends a plain-text turn. On success, both the user message and the
  /// assistant reply are appended to the running history. On failure,
  /// nothing is appended and a [GroqApiException] is thrown.
  Future<String> sendMessage(String userMessage) async {
    _ensureApiKey();

    final provisional = List<Map<String, dynamic>>.from(_conversationHistory)
      ..add({'role': 'user', 'content': userMessage});

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(_chatUrl),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'model': _textModel,
          'messages': provisional,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );
    } on SocketException {
      throw GroqApiException(
          'No internet connection. Check your network and try again.');
    } on HttpException {
      throw GroqApiException('Network error while contacting the assistant.');
    } catch (e) {
      throw GroqApiException('Unexpected error: $e');
    }

    if (response.statusCode != 200) {
      throw _errorForStatus(response);
    }

    final assistantMessage = _extractAssistantContent(response);
    _conversationHistory
      ..add({'role': 'user', 'content': userMessage})
      ..add({'role': 'assistant', 'content': assistantMessage});
    return assistantMessage;
  }

  /// Sends a vision turn (image + optional caption). On success the user's
  /// turn is recorded as text (we do not re-upload the image with every
  /// follow-up — a short text placeholder keeps history lightweight).
  Future<String> sendImageMessage(
    File imageFile, {
    String? additionalText,
  }) async {
    _ensureApiKey();

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final userText = additionalText ??
        'I have this home issue. Please look at this photo and tell me '
            'what the problem might be, whether I can fix it myself safely, '
            'or if I need to call a professional.';

    final visionTurn = <String, dynamic>{
      'role': 'user',
      'content': [
        {'type': 'text', 'text': userText},
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
        },
      ],
    };

    final provisional = List<Map<String, dynamic>>.from(_conversationHistory)
      ..add(visionTurn);

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(_chatUrl),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'model': _visionModel,
          'messages': provisional,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );
    } on SocketException {
      throw GroqApiException(
          'No internet connection. Check your network and try again.');
    } catch (e) {
      throw GroqApiException('Could not analyze the image: $e');
    }

    if (response.statusCode != 200) {
      throw _errorForStatus(response);
    }

    final assistantMessage = _extractAssistantContent(response);
    // Store a text-only placeholder for the user turn so we don't keep
    // a base64 blob in history on every subsequent call.
    _conversationHistory
      ..add({
        'role': 'user',
        'content':
            additionalText ?? '[User sent a photo of their home issue]',
      })
      ..add({'role': 'assistant', 'content': assistantMessage});
    return assistantMessage;
  }

  /// Transcribes an audio file via Whisper. Throws [GroqApiException] on
  /// any failure; callers should treat the result as trusted transcript.
  Future<String> transcribeAudio(File audioFile) async {
    _ensureApiKey();

    final request = http.MultipartRequest('POST', Uri.parse(_audioUrl))
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = _transcriptionModel
      ..fields['language'] = 'en'
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final http.Response response;
    try {
      final streamed = await request.send();
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw GroqApiException('No internet connection. Try again later.');
    } catch (e) {
      throw GroqApiException('Could not transcribe audio: $e');
    }

    if (response.statusCode != 200) {
      throw _errorForStatus(response);
    }

    final data = jsonDecode(response.body);
    final text = (data['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw GroqApiException(
          'Could not transcribe the recording — please try again.');
    }
    return text;
  }

  /// Transcribes a voice recording and feeds the transcript into the chat
  /// pipeline. Returns the transcript + model reply together so callers
  /// can update the user bubble in-place.
  Future<Map<String, String>> sendVoiceMessage(File audioFile) async {
    final transcription = await transcribeAudio(audioFile);
    final reply = await sendMessage(transcription);
    return {'transcription': transcription, 'response': reply};
  }

  /// Wipes the running conversation back down to the system prompt.
  void clearHistory() {
    if (_conversationHistory.isEmpty) return;
    _conversationHistory.removeRange(1, _conversationHistory.length);
  }

  // ─── helpers ───────────────────────────────────────────────────────────

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw GroqApiException(
          'Assistant is not configured. Please contact support.');
    }
  }

  String _extractAssistantContent(http.Response response) {
    final data = jsonDecode(response.body);
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      throw GroqApiException('The assistant returned an empty reply.',
          raw: response.body);
    }
    final content = choices[0]['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw GroqApiException('The assistant returned an empty reply.',
          raw: response.body);
    }
    return content;
  }

  GroqApiException _errorForStatus(http.Response response) {
    final code = response.statusCode;
    final friendly = switch (code) {
      401 || 403 =>
        'Assistant authentication failed. Please contact support.',
      408 => 'The assistant took too long to respond. Please try again.',
      429 => 'Too many requests right now. Please wait a moment and retry.',
      >= 500 =>
        'The assistant is temporarily unavailable. Please try again shortly.',
      _ => 'The assistant could not process that request. Please try again.',
    };
    return GroqApiException(friendly, statusCode: code, raw: response.body);
  }
}
