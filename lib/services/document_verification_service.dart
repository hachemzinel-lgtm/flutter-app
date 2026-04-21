import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:read_pdf_text/read_pdf_text.dart';

class VerificationResult {
  const VerificationResult({
    required this.isValid,
    required this.documentType,
    required this.reason,
    required this.extractedText,
  });

  final bool isValid;
  final String documentType;
  final String reason;
  final String extractedText;
}

class CombinedVerificationResult {
  const CombinedVerificationResult({
    required this.status,
    required this.reason,
    required this.professionalDocument,
    required this.identityDocument,
  });

  final String status;
  final String reason;
  final VerificationResult professionalDocument;
  final VerificationResult identityDocument;
}

class DocumentVerificationService {
  static Future<CombinedVerificationResult> verifyProviderDocuments({
    required File professionalDocument,
    required File identityDocument,
  }) async {
    print('--- [DOC VERIFY] Starting provider document verification');
    try {
      final diplomaText = await ReadPdfText.getPDFtext(
        professionalDocument.path,
      );
      final idText = await ReadPdfText.getPDFtext(identityDocument.path);

      if (diplomaText.trim().isEmpty || idText.trim().isEmpty) {
        return const CombinedVerificationResult(
          status: 'rejected',
          reason:
              'One or both documents could not be read clearly. Please upload clearer PDF files.',
          professionalDocument: VerificationResult(
            isValid: false,
            documentType: 'unknown',
            reason: 'Professional document could not be read.',
            extractedText: '',
          ),
          identityDocument: VerificationResult(
            isValid: false,
            documentType: 'unknown',
            reason: 'Identity document could not be read.',
            extractedText: '',
          ),
        );
      }

      await _ensureEnvLoaded();
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyAF6wgGfZUkuCpDdBhi1-ot2DYXqkhPPPw';
      if (apiKey.isEmpty) {
        return CombinedVerificationResult(
          status: 'rejected',
          reason: 'Gemini API key is missing. Manual review is required.',
          professionalDocument: VerificationResult(
            isValid: false,
            documentType: 'certificate',
            reason: 'AI verification is not configured.',
            extractedText: diplomaText,
          ),
          identityDocument: VerificationResult(
            isValid: false,
            documentType: 'id_card',
            reason: 'AI verification is not configured.',
            extractedText: idText,
          ),
        );
      }

      final responseText = await _requestVerification(
        _buildPrompt(professionalText: diplomaText, identityText: idText),
      );

      final payload = _parseResponse(responseText);
      final diplomaValid = payload['diploma_valid'] == true;
      final idValid = payload['id_valid'] == true;
      final reason =
          payload['reason']?.toString() ??
          'Verification completed without a detailed reason.';

      return CombinedVerificationResult(
        status: diplomaValid && idValid ? 'approved' : 'rejected',
        reason: reason,
        professionalDocument: VerificationResult(
          isValid: diplomaValid,
          documentType: 'certificate',
          reason: reason,
          extractedText: diplomaText,
        ),
        identityDocument: VerificationResult(
          isValid: idValid,
          documentType: 'id_card',
          reason: reason,
          extractedText: idText,
        ),
      );
    } catch (error) {
      return CombinedVerificationResult(
        status: 'rejected',
        reason: 'Automated verification failed: $error',
        professionalDocument: const VerificationResult(
          isValid: false,
          documentType: 'certificate',
          reason: 'Automated verification failed.',
          extractedText: '',
        ),
        identityDocument: const VerificationResult(
          isValid: false,
          documentType: 'id_card',
          reason: 'Automated verification failed.',
          extractedText: '',
        ),
      );
    }
  }

  static Future<void> _ensureEnvLoaded() async {
    if (dotenv.isInitialized) {
      return;
    }

    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Intentionally ignored so the caller can handle missing keys gracefully.
    }
  }

  static Future<String> _requestVerification(
    String prompt,

  ) async {
    const model = 'gemini-2.5-flash';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=AIzaSyAF6wgGfZUkuCpDdBhi1-ot2DYXqkhPPPw';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 256},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) {
      return '{}';
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>? ?? const {};
    final parts = content['parts'] as List<dynamic>? ?? const [];
    if (parts.isEmpty) {
      return '{}';
    }

    final firstPart = parts.first as Map<String, dynamic>;
    return firstPart['text']?.toString() ?? '{}';
  }

  static String _buildPrompt({
    required String professionalText,
    required String identityText,
  }) {
    return '''
Analyze these documents. Document 1 should be a professional certificate, diploma, or license. Document 2 should be an ID card.

Return only JSON with this exact structure:
{"diploma_valid": true, "id_valid": true, "reason": "short explanation"}

DOCUMENT 1 TEXT:
$professionalText

DOCUMENT 2 TEXT:
$identityText
''';
  }

  static Map<String, dynamic> _parseResponse(String rawResponse) {
    final cleaned = rawResponse
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}
