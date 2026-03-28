import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../lib/services/groq_chat_service.dart';

void main() async {
  print('--- Groq Service Verification ---');
  
  // 1. Check if .env exists
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('❌ ERROR: .env file missing in project root!');
    exit(1);
  }
  print('✅ .env file found.');

  // 2. Load .env
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded.');
  } catch (e) {
    print('❌ ERROR: Failed to load .env: $e');
    exit(1);
  }

  // 3. Verify Key
  final key = dotenv.env['GROQ_API_KEY'];
  if (key == null || key.isEmpty) {
    print('❌ ERROR: GROQ_API_KEY not found in .env!');
    exit(1);
  }
  print('✅ API Key found (starts with: ${key.substring(0, 7)}...)');

  // 4. Test Service
  final service = GroqChatService();
  print('🚀 Sending test message to Groq...');
  
  try {
    final response = await service.sendMessage('Hello! This is a connection test. Please reply with "READY".');
    print('\n🤖 AI RESPONSE:');
    print('-----------------------------------');
    print(response);
    print('-----------------------------------');
    
    if (response.toLowerCase().contains('ready') || (response.isNotEmpty && !response.contains('Error'))) {
      print('\n✨ VERIFICATION SUCCESSFUL: Groq Chatbot is operational!');
    } else {
      print('\n⚠️ WARNING: Received unexpected response format.');
    }
  } catch (e) {
    print('❌ ERROR: Service call failed: $e');
    exit(1);
  }
}
