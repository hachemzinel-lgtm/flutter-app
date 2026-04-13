import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/verification_result.dart';

class DocumentVerificationRepository {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  final String _chatUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  Future<DocumentVerificationResult> verifyDocument({
    required File imageFile,
    required String uid,
  }) async {
    try {
      final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('credentials/$uid/$fileName');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": _visionModel,
          "messages": [
            {
              "role": "system",
              "content": "You are a professional credential verification assistant embedded in a service marketplace platform. Your task is to analyze images of professional documents uploaded by tradespeople and service professionals. You must respond ONLY with a valid JSON object. No explanation, no preamble, no markdown. Only raw JSON. Required format: {\"isLegible\": true or false, \"isOfficialDocument\": true or false, \"detectedCategory\": \"string or null\", \"confidence\": \"high\" or \"medium\" or \"low\", \"reason\": \"one concise sentence\"}. isLegible means the text is clearly readable, not blurry or cut off. isOfficialDocument means it shows at least two of: person name, issuing institution, date, stamp, signature, certificate number. confidence is high for clear documents, medium for partially unclear, low for too much uncertainty. Do not hallucinate."
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "image_url",
                  "image_url": { "url": "data:image/jpeg;base64,$base64Image" }
                },
                {
                  "type": "text",
                  "text": "Analyze this professional credential document."
                }
              ]
            }
          ],
          "max_tokens": 300,
          "temperature": 0.1
        }),
      );

      DocumentVerificationResult result;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'] as String;
        
        content = content.replaceAll(RegExp(r'```json\n?'), '');
        content = content.replaceAll(RegExp(r'\n?```'), '');
        content = content.trim();

        try {
          final jsonMap = jsonDecode(content);
          
          bool isLegible = jsonMap['isLegible'] == true;
          bool isOfficialDoc = jsonMap['isOfficialDocument'] == true;
          String confidence = jsonMap['confidence'] as String? ?? 'low';
          
          bool isVerified = isLegible && isOfficialDoc && confidence != 'low';
          
          jsonMap['isVerified'] = isVerified;
          result = DocumentVerificationResult.fromJson(jsonMap);
          
        } catch (e) {
          result = DocumentVerificationResult(
            isVerified: false,
            isLegible: false,
            isOfficialDocument: false,
            confidence: 'low',
            reason: 'Could not process document JSON format. Please try again.',
          );
        }
      } else {
        result = DocumentVerificationResult(
          isVerified: false,
          isLegible: false,
          isOfficialDocument: false,
          confidence: 'low',
          reason: 'API request failed. Please try again.',
        );
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'verificationStatus': result.isVerified ? 'ai_verified' : 'unverified',
        'badgeVisible': result.isVerified,
        'documentUrl': downloadUrl,
        'verificationReason': result.reason,
        'verificationConfidence': result.confidence,
        'verificationTimestamp': Timestamp.now(),
        'verificationAttempts': FieldValue.increment(1),
      });

      return result;
    } catch (e) {
      return DocumentVerificationResult(
        isVerified: false,
        isLegible: false,
        isOfficialDocument: false,
        confidence: 'low',
        reason: 'Could not process document. Please try again. Error: $e',
      );
    }
  }
}
