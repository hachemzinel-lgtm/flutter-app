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
    final professionalResult = await verifyDocument(
      professionalDocument,
      documentPurpose: 'professional_certificate',
    );
    final identityResult = await verifyDocument(
      identityDocument,
      documentPurpose: 'identity_document',
    );

    final approved = professionalResult.isValid && identityResult.isValid;
    final reason = approved
        ? 'Documents approved by automated verification.'
        : [
            if (!professionalResult.isValid) professionalResult.reason,
            if (!identityResult.isValid) identityResult.reason,
          ].join(' ');

    return CombinedVerificationResult(
      status: approved ? 'approved' : 'rejected',
      reason: reason,
      professionalDocument: professionalResult,
      identityDocument: identityResult,
    );
  }

  static Future<VerificationResult> verifyDocument(
    File pdfFile, {
    required String documentPurpose,
  }) async {
    try {
      final extractedText = await ReadPdfText.getPDFtext(pdfFile.path);
      if (extractedText.trim().isEmpty) {
        return const VerificationResult(
          isValid: false,
          documentType: 'unknown',
          reason: 'Document is not readable. Please upload a clear PDF file.',
          extractedText: '',
        );
      }

      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        return VerificationResult(
          isValid: false,
          documentType: 'unknown',
          reason: 'Gemini API key is missing. Manual admin review required.',
          extractedText: extractedText,
        );
      }

      final prompt = _buildPrompt(
        documentPurpose: documentPurpose,
        extractedText: extractedText,
      );
      final responseText = await _requestVerification(prompt, apiKey);
      final result = _parseResponse(responseText);

      return VerificationResult(
        isValid: result['isValid'] == true,
        documentType: (result['documentType'] ?? 'unknown').toString(),
        reason: (result['reason'] ?? 'Verification completed').toString(),
        extractedText: extractedText,
      );
    } catch (error) {
      return VerificationResult(
        isValid: false,
        documentType: 'unknown',
        reason: 'Automated verification failed: $error',
        extractedText: '',
      );
    }
  }

  static Future<String> _requestVerification(String prompt, String apiKey) async {
    const model = 'gemini-1.5-flash';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

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
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 256,
        },
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
    required String documentPurpose,
    required String extractedText,
  }) {
    final purposeDescription = documentPurpose == 'identity_document'
        ? 'Check that this text looks like an ID card or passport and contains a real person name plus an ID number.'
        : 'Check that this text looks like a professional diploma, certificate, or work license.';

    return '''
Analyze the following OCR text from a PDF.
$purposeDescription

Return only JSON with this exact structure:
{"isValid": true, "documentType": "diploma|certificate|license|id_card|passport|unknown", "reason": "short explanation"}

OCR TEXT:
$extractedText
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
