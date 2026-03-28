import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // System error pill
    if (message.role == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      );
    }

    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentBlue : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE type - render thumbnail
            if (message.type == MessageType.image && message.imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  message.imageFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                ),
              ),

            // Gap between image and caption
            if (message.type == MessageType.image && message.imageFile != null && message.content.isNotEmpty)
              const SizedBox(height: 6),

            // VOICE type pill
            if (message.type == MessageType.voice) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 15, color: isUser ? Colors.white : AppColors.accentBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Voice message',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isUser ? Colors.white : AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
              if (message.transcription != null && message.transcription!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'You said: "${message.transcription}"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isUser ? Colors.white70 : const Color(0xFF666666),
                  ),
                ),
              ],
            ],

            // TEXT content (also used as image caption)
            if (message.content.isNotEmpty && message.type != MessageType.voice)
              Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1C1C1E),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isUser ? Colors.white54 : const Color(0xFF999999),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
