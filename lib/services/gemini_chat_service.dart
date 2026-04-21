import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// A single, unified chat service backed by Gemini 2.0 Flash.
/// Handles plain text, image (multimodal), and voice (audio transcription → chat).
/// Maintains full conversation history for multi-turn context.
class GeminiChatService {
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const String _systemPrompt =
      'You are FixIt AI, a world-class home repair and maintenance assistant. '
      'Help users diagnose, plan, and safely fix home issues. '
      'Be concise, practical, and safety-conscious. '
      'When you identify a specific trade category (Plumbing, Electrical, Cleaning, '
      'Painting, Carpentry, HVAC, or Landscaping), mention it naturally in your reply '
      'so the user can find a local professional if needed.';

  /// Internal history stored in a simple role/content format.
  /// Role is either "user" or "assistant".
  final List<Map<String, dynamic>> _history = [];

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Replaces the in-memory history (used when loading a persisted session).
  void setHistory(List<Map<String, dynamic>> history) {
    _history
      ..clear()
      ..addAll(history);
  }

  /// Wipes history (new session).
  void clearHistory() => _history.clear();

  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  // ─── Text ──────────────────────────────────────────────────────────────────

  Future<String> sendMessage(String text) async {
    final userTurn = _textTurn('user', text);
    final reply = await _callGemini([..._historyAsGeminiContents(), userTurn]);

    _history
      ..add({'role': 'user', 'content': text})
      ..add({'role': 'assistant', 'content': reply});

    return reply;
  }

  // ─── Image ─────────────────────────────────────────────────────────────────

  Future<String> sendImageMessage(
    File imageFile, {
    String? additionalText,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = _imageMime(imageFile.path);

    final prompt = (additionalText != null && additionalText.isNotEmpty)
        ? additionalText
        : 'Analyze this image and identify any home repair issues or maintenance '
            'concerns you can see. Provide specific advice.';

    final userTurn = {
      'role': 'user',
      'parts': [
        {
          'inlineData': {'mimeType': mime, 'data': b64}
        },
        {'text': prompt},
      ],
    };

    final reply = await _callGemini([..._historyAsGeminiContents(), userTurn]);

    _history
      ..add({'role': 'user', 'content': additionalText ?? '[Image attached]'})
      ..add({'role': 'assistant', 'content': reply});

    return reply;
  }

  // ─── Voice ─────────────────────────────────────────────────────────────────

  /// Step 1 – transcribe.  Step 2 – chat reply.
  /// Returns a record with both the transcript and the AI reply.
  Future<({String transcript, String reply})> sendVoiceMessage(
    File audioFile,
  ) async {
    final transcript = await _transcribeAudio(audioFile);
    if (transcript.isEmpty) {
      throw Exception('Could not transcribe audio — please try again.');
    }
    final reply = await sendMessage(transcript); // reuses text flow + history
    return (transcript: transcript, reply: reply);
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<String> _transcribeAudio(File audioFile) async {
    final bytes = await audioFile.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = _audioMime(audioFile.path);

    // One-shot transcription call — no history needed.
    final contents = [
      {
        'role': 'user',
        'parts': [
          {
            'inlineData': {'mimeType': mime, 'data': b64}
          },
          {
            'text':
                'Transcribe this audio recording exactly as spoken. '
                'Return only the transcription text with no additional commentary.'
          },
        ],
      }
    ];

    return _callGemini(contents, maxTokens: 512, temperature: 0.1);
  }

  List<Map<String, dynamic>> _historyAsGeminiContents() {
    return _history.map((msg) {
      return {
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': msg['content']}
        ],
      };
    }).toList();
  }

  Map<String, dynamic> _textTurn(String role, String text) => {
        'role': role == 'assistant' ? 'model' : role,
        'parts': [
          {'text': text}
        ],
      };

  Future<String> _callGemini(
    List<Map<String, dynamic>> contents, {
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    await _ensureEnvLoaded();
    final key = dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyAF6wgGfZUkuCpDdBhi1-ot2DYXqkhPPPw';
    if (key.isEmpty) throw Exception('GEMINI_API_KEY is not set in .env');

    final url = '$_baseUrl/$_model:generateContent?key=$key';

    final body = jsonEncode({
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      },
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini ${response.statusCode}: '
        '${(jsonDecode(response.body) as Map)['error']?['message'] ?? response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) throw Exception('Gemini returned no candidates.');

    final parts =
        (candidates.first['content']['parts'] as List<dynamic>? ?? []);
    return parts.map((p) => p['text']?.toString() ?? '').join();
  }

  // ─── Env & MIME helpers ────────────────────────────────────────────────────

  static bool _envLoaded = false;

  static Future<void> _ensureEnvLoaded() async {
    if (_envLoaded || dotenv.isInitialized) {
      _envLoaded = true;
      return;
    }
    try {
      await dotenv.load(fileName: '.env');
      _envLoaded = true;
    } catch (_) {
      // Caller handles missing key gracefully.
    }
  }

  static String _imageMime(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  static String _audioMime(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'webm':
        return 'audio/webm';
      default:
        return 'audio/mp4'; // m4a / aac
    }
  }
}
