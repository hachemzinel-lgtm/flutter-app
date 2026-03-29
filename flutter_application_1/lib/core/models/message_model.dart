import 'dart:io';

/// The type of content a message contains.
enum MessageType { text, image, voice }

class MessageModel {
  final String role; // 'user', 'assistant', or 'system'
  final String content;
  final MessageType type;
  final File? imageFile;
  final String? transcription; // for voice messages – the Whisper transcription
  final DateTime timestamp;

  MessageModel({
    required this.role,
    required this.content,
    this.type = MessageType.text,
    this.imageFile,
    this.transcription,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
}
