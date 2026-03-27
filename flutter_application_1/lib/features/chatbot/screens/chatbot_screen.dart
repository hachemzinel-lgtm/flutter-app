import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as prov;
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return prov.ChangeNotifierProvider(
      create: (_) => ChatProvider()..addListener(_scrollToBottom),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF0F7FF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
              ),
              Text(
                'Ask me anything about repairs',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.softGray,
                ),
              ),
            ],
          ),
          actions: [
            prov.Consumer<ChatProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.softGray,
                  ),
                  onPressed: () => _showClearDialog(context, provider),
                  tooltip: 'Clear Chat',
                );
              },
            ),
          ],
        ),
        body: prov.Consumer<ChatProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: provider.messages[index]);
                    },
                  ),
                ),
                if (provider.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI is thinking...',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.softGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                MessageInput(
                  onSend: (text, {imageBase64, audioBase64}) async {
                    await provider.sendMessage(
                      text,
                      imageBase64: imageBase64,
                      audioBase64: audioBase64,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear your conversation history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.softGray),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
