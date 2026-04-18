import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class AiChatException implements Exception {
  final String message;
  const AiChatException(this.message);

  @override
  String toString() => 'AiChatException: $message';
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class AiChatService {
  static const String _apiKey = 'AIzaSyCWUMsT88OAb6PjUsVh2R9Lztdx7x-W-eA';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';

  static const String _systemPrompt = '''
You are NearWork Assistant, a smart and friendly service advisor embedded in a home services marketplace app.

Your responsibilities:
1. Help users identify and understand household problems (plumbing, electrical, cleaning, carpentry, painting, masonry, AC, roofing, pest control, etc.)
2. Ask short clarifying questions to better understand the issue before recommending
3. Recommend the correct type of professional or supplier once you understand the problem
4. If the question is unrelated to home services or the NearWork platform, politely explain your specialization and suggest the user consult the appropriate resource
5. Keep all responses concise, practical, and friendly
6. When you have clearly identified what type of service or product the user needs, append exactly this on a new line at the end of your message:
   SEARCH_SUGGESTION:[category]
   Valid categories: Plumber, Electrician, Cleaner, Carpenter, Painter, Mason, AC Technician, Roofer, Locksmith, Gardener, Pest Control, Materials Supplier, Tools & Equipment, Spare Parts, General Hardware
   Example: SEARCH_SUGGESTION:Plumber
''';

  // Converts internal history format to Gemini contents format
  // history: List of {role: 'user'|'model', content: 'text'}
  List<Map<String, dynamic>> _buildContents(
    String userMessage,
    List<Map<String, String>> history,
  ) {
    final List<Map<String, dynamic>> contents = [];

    if (history.isEmpty) {
      // First ever message — inject system prompt here
      contents.add({
        'role': 'user',
        'parts': [
          {'text': 'SYSTEM INSTRUCTIONS:\n$_systemPrompt\n\n$userMessage'},
        ],
      });
    } else {
      // Inject system prompt into the very first history message
      final firstMsg = history[0];
      contents.add({
        'role': 'user',
        'parts': [
          {
            'text':
                'SYSTEM INSTRUCTIONS:\n$_systemPrompt\n\n${firstMsg['content']}',
          },
        ],
      });
      // Add remaining history
      for (int i = 1; i < history.length; i++) {
        final rawRole = history[i]['role'] ?? 'user';
        final role = (rawRole == 'assistant' || rawRole == 'model')
            ? 'model'
            : 'user';

        contents.add({
          'role': role,
          'parts': [
            {'text': history[i]['content'] ?? ''},
          ],
        });
      }
      // Add new user message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      });
    }
    return contents;
  }

  Future<String> sendMessage(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    final contents = _buildContents(userMessage, history);
    final requestBody = {'contents': contents};

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw AiChatException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw AiChatException(
        'Gemini HTTP ${response.statusCode}: ${response.body}',
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text;
    } catch (e) {
      throw AiChatException('Failed to parse Gemini response: $e');
    }
  }

  Future<String> sendMessageWithImage(
    String userText,
    Uint8List imageBytes,
    List<Map<String, String>> history,
  ) async {
    final contents = _buildContents(userText, history);
    
    // Replace the last user entry (which just has text) with a multi-part entry
    final lastContent = contents.last;
    lastContent['parts'] = [
      {
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Encode(imageBytes),
        },
      },
      {'text': userText.isEmpty ? 'Please analyze this image.' : userText},
    ];

    final requestBody = {'contents': contents};

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 45)); // Slightly longer timeout for images
    } catch (e) {
      throw AiChatException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw AiChatException(
        'Gemini HTTP ${response.statusCode}: ${response.body}',
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text;
    } catch (e) {
      throw AiChatException('Failed to parse Gemini response: $e');
    }
  }
}
