import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:read_pdf_text/read_pdf_text.dart';

class VerificationResult {
  final bool isValid;
  final String documentType;
  final String reason;

  VerificationResult({
    required this.isValid,
    required this.documentType,
    required this.reason,
  });
}

class DocumentVerificationService {
  static Future<VerificationResult> verifyDocument(File pdfFile) async {
    try {
      // 1. Extraire le texte du PDF via read_pdf_text
      String docText = await ReadPdfText.getPDFtext(pdfFile.path);
      
      // Si le texte est vide (image-only PDF), on passe quand même à l'étape suivante
      // car Gemini Vision (si supporté) ou l'analyse base64 pourrait aider.
      // Mais ici le prompt demande l'extraction OCR d'abord.

      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('Gemini API key not configured');

      const model = 'gemini-1.5-flash';
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '''Analyze the following text extracted from a document. 
Determine if it is a valid professional certification, diploma, or work license. 
Also check if it is a valid ID card containing a person's name and ID number.

EXTRACTED TEXT:
$docText

Return ONLY a JSON object (no markdown) in this exact format:
{"isValid": true/false, "documentType": "professional_certificate|work_license|diploma|id_card|unknown", "reason": "brief explanation"}'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 256,
        }
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';

      // Strip markdown if present
      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final result = jsonDecode(cleaned);

      return VerificationResult(
        isValid: result['isValid'] == true,
        documentType: result['documentType'] ?? 'unknown',
        reason: result['reason'] ?? 'Could not determine',
      );
    } catch (e) {
      // If API fails, return a pending state so admin can manually review
      return VerificationResult(
        isValid: false,
        documentType: 'unknown',
        reason: 'Automated verification failed: ${e.toString()}. Manual review required.',
      );
    }
  }
}
