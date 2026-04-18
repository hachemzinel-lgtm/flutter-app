import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/ai_chat_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class AiChatSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const AiChatSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<AiChatSessionScreen> createState() => _AiChatSessionScreenState();
}

class _AiChatSessionScreenState extends ConsumerState<AiChatSessionScreen> {
  File? _selectedImage;
  bool _isSending = false;
  
  // Local cache for images sent during this session to maintain UI consistency
  // Maps message timestamp/ID to the local File
  final Map<String, File> _localImages = {};

  Future<void> _pickImage() async {
    if (_isSending) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.accentBlue),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() => _selectedImage = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.accentBlue),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _selectedImage = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _selectedImage != null
          ? Container(
              key: const ValueKey('image_preview'),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _isSending ? null : () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty_preview')),
    );
  }

  Future<void> _handleSend(String text, List<Map<String, dynamic>> messages) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    if (_selectedImage != null) {
      await _sendImageMessage(text, messages, user.uid);
    } else if (text.trim().isNotEmpty) {
      final history = messages.reversed.map((m) => {
        'role': m['role'] as String,
        'content': m['content'] as String,
      }).toList();

      ref.read(activeChatControllerProvider(widget.sessionId))
         .sendMessage(text, history);
    }
  }

  Future<void> _sendImageMessage(String text, List<Map<String, dynamic>> messages, String userId) async {
    setState(() => _isSending = true);

    try {
      // STEP 1 — Read image bytes into memory
      final Uint8List imageBytes = await _selectedImage!.readAsBytes();
      final File imageFile = _selectedImage!;
      
      // Generate a temporary ID to track this image in the local cache
      final String tempId = DateTime.now().millisecondsSinceEpoch.toString();
      _localImages[tempId] = imageFile;

      // STEP 4 — Save user message to Firestore (text only)
      final userMessage = {
        'role': 'user',
        'content': text.isEmpty ? '[Image]' : text,
        'type': 'image_text',
        'localId': tempId, // Custom field to link Firestore doc to local image cache
      };
      
      await ref.read(aiChatRepositoryProvider).addMessage(userId, widget.sessionId, userMessage);

      // STEP 5 — Call Gemini with image bytes + text
      final history = messages.reversed.map((m) => {
        'role': m['role'] as String,
        'content': m['content'] as String,
      }).toList();

      final reply = await ref.read(aiChatServiceProvider).sendMessageWithImage(text, imageBytes, history);

      // STEP 6 — Save AI response to Firestore
      final assistantMessage = {
        'role': 'model',
        'content': reply,
        'type': 'text',
      };
      await ref.read(aiChatRepositoryProvider).addMessage(userId, widget.sessionId, assistantMessage);

      // STEP 8 — Cleanup
      setState(() {
        _selectedImage = null;
        _isSending = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI service error: $e')),
        );
      }
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authStateProvider);
    final user = userState.value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized access')));
    }

    final messagesAsync = ref.watch(sessionMessagesProvider((userId: user.uid, sessionId: widget.sessionId)));
    final stateAsync = ref.watch(activeChatStateProvider(widget.sessionId));

    // Listen for errors to show snackbars
    ref.listen<AsyncValue<ActiveChatState>>(activeChatStateProvider(widget.sessionId), (previous, next) {
      if (next.hasValue && next.value!.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.value!.error!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    });

    final currentUser = ChatUser(
      id: user.uid,
      firstName: user.displayName ?? 'Me',
      profileImage: user.photoURL,
    );

    final aiUser = ChatUser(
      id: 'assistant',
      firstName: 'NearWork Assistant',
      profileImage: 'https://cdn-icons-png.flaticon.com/512/4712/4712038.png',
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Diagnosis', style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: messagesAsync.when(
        data: (messages) {
          final chatMessages = messages.map((m) {
            final String? localId = m['localId'] as String?;
            final File? localFile = localId != null ? _localImages[localId] : null;
            
            return ChatMessage(
              user: m['role'] == 'user' ? currentUser : aiUser,
              text: m['content'] as String,
              createdAt: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              customProperties: localFile != null ? {'localFile': localFile} : null,
            );
          }).toList();

          return Stack(
            children: [
              DashChat(
                currentUser: currentUser,
                onSend: (ChatMessage msg) => _handleSend(msg.text, messages),
                messages: chatMessages,
                messageOptions: MessageOptions(
                  showOtherUsersAvatar: true,
                  showTime: true,
                  containerColor: AppColors.backgroundSecondary,
                  currentUserContainerColor: AppColors.accentBlue,
                  textColor: AppColors.textDark,
                  currentUserTextColor: AppColors.white,
                  messageTextBuilder: (message, previousMessage, nextMessage) {
                    final text = message.text;
                    final File? localFile = message.customProperties?['localFile'] as File?;
                    
                    final suggestionMatch = RegExp(r'SEARCH_SUGGESTION: ([\w ]+)').firstMatch(text);

                    return Column(
                      crossAxisAlignment: message.user.id == currentUser.id 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.start,
                      children: [
                        if (localFile != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                localFile,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (suggestionMatch != null) ...[
                          _buildSuggestionContent(message, text, suggestionMatch, currentUser.id),
                        ] else if (text.isNotEmpty && text != '[Image]') ...[
                          Text(
                            text,
                            style: TextStyle(
                              color: message.user.id == currentUser.id 
                                  ? AppColors.white 
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                inputOptions: InputOptions(
                  alwaysShowSend: true,
                  leading: [
                    IconButton(
                      icon: const Icon(Icons.image_rounded, color: AppColors.accentBlue),
                      onPressed: _isSending ? null : _pickImage,
                    ),
                  ],
                  inputDecoration: InputDecoration(
                    hintText: 'Describe your problem...',
                    fillColor: AppColors.softGray.withValues(alpha: 0.1),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  sendButtonBuilder: (onSend) {
                    final isSending = (stateAsync.value?.isSending ?? false) || _isSending;
                    if (isSending) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.accentBlue),
                      onPressed: onSend,
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: _buildImagePreview(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSuggestionContent(ChatMessage message, String text, RegExpMatch suggestionMatch, String currentUserId) {
    final category = suggestionMatch.group(1)!.trim();
    final cleanText = text.replaceAll(RegExp(r'SEARCH_SUGGESTION: [\w ]+'), '').trim();

    return Column(
      crossAxisAlignment: message.user.id == currentUserId 
          ? CrossAxisAlignment.end 
          : CrossAxisAlignment.start,
      children: [
        if (cleanText.isNotEmpty)
          Text(
            cleanText,
            style: TextStyle(
              color: message.user.id == currentUserId 
                  ? AppColors.white 
                  : AppColors.textDark,
            ),
          ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.push('/search-results?category=$category'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 18, color: AppColors.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Find $category',
                    style: const TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
