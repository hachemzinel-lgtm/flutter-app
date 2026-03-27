class MessageModel {
  final String role; // 'user', 'assistant', or 'system'
  final String content;
  final String? imageBase64;
  final String? audioBase64; // NEW for Gemini native audio support
  final DateTime timestamp;

  MessageModel({
    required this.role,
    required this.content,
    this.imageBase64,
    this.audioBase64,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'imageBase64': imageBase64,
      'audioBase64': audioBase64,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      role: json['role'] as String,
      content: json['content'] as String,
      imageBase64: json['imageBase64'] as String?,
      audioBase64: json['audioBase64'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
