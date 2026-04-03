import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, this.otherName});

  final String conversationId;
  final String? otherName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isSending = false;
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _playingMessageId = null);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendTextMessage(UserModel currentUser) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(chatServiceProvider)
          .sendTextMessage(
            conversationId: widget.conversationId,
            sender: currentUser,
            content: text,
          );
      _messageController.clear();
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _showImageSourcePicker(UserModel currentUser) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1800,
    );
    if (pickedFile == null) {
      return;
    }

    await ref
        .read(chatServiceProvider)
        .sendMediaMessage(
          conversationId: widget.conversationId,
          sender: currentUser,
          file: File(pickedFile.path),
          type: ChatMessageType.photo,
        );
    _scrollToBottom();
  }

  Future<void> _toggleRecording(UserModel currentUser) async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (!mounted) {
        return;
      }
      setState(() => _isRecording = false);

      if (path == null || path.isEmpty) {
        return;
      }

      await ref
          .read(chatServiceProvider)
          .sendMediaMessage(
            conversationId: widget.conversationId,
            sender: currentUser,
            file: File(path),
            type: ChatMessageType.voice,
          );
      _scrollToBottom();
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone permission is required to send voice messages.',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (mounted) {
      setState(() => _isRecording = true);
    }
  }

  Future<void> _toggleVoicePlayback(MarketplaceChatMessage message) async {
    if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
      return;
    }

    if (_playingMessageId == message.id) {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() => _playingMessageId = null);
      }
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(message.mediaUrl!));
    if (mounted) {
      setState(() => _playingMessageId = message.id);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserDocProvider).value;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));

    return conversationAsync.when(
      data: (conversation) {
        if (conversation == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.otherName ?? 'Conversation')),
            body: const Center(
              child: Text('This conversation is no longer available.'),
            ),
          );
        }

        final otherName =
            conversation.otherParticipantName(currentUser.id).trim().isEmpty
            ? (widget.otherName ?? 'NearWork user')
            : conversation.otherParticipantName(currentUser.id);
        final otherPhoto = conversation.otherParticipantPhoto(currentUser.id);
        final otherType = conversation.otherParticipantType(currentUser.id);
        final otherId = conversation.otherParticipantId(currentUser.id);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(chatServiceProvider)
              .markConversationRead(
                conversationId: widget.conversationId,
                userId: currentUser.id,
              );
        });

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
                  backgroundImage: otherPhoto != null && otherPhoto.isNotEmpty
                      ? NetworkImage(otherPhoto)
                      : null,
                  child: otherPhoto != null && otherPhoto.isNotEmpty
                      ? null
                      : Text(
                          (otherName.isNotEmpty
                                  ? otherName.substring(0, 1)
                                  : '?')
                              .toUpperCase(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingSmall,
                      ),
                      Text(
                        otherType?.displayName ?? 'NearWork user',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.availableGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (currentUser.userType == UserType.client &&
                  otherType != UserType.client)
                IconButton(
                  icon: const Icon(
                    Icons.star_border_rounded,
                    color: AppColors.starGold,
                  ),
                  tooltip: 'Rate this experience',
                  onPressed: otherId.isEmpty
                      ? null
                      : () => context.push('/rate-service/$otherId'),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    _scrollToBottom();
                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: AppSpacing.pagePadding,
                          child: Text(
                            'Start the conversation with $otherName.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.m,
                        AppSpacing.l,
                        AppSpacing.m,
                        AppSpacing.m,
                      ),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.m),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUser.id;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: _MessageBubble(
                            message: message,
                            isMe: isMe,
                            isPlaying: _playingMessageId == message.id,
                            onPlayVoice: message.type == ChatMessageType.voice
                                ? () => _toggleVoicePlayback(message)
                                : null,
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Unable to load messages.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.s,
                    AppSpacing.m,
                    AppSpacing.m,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _showImageSourcePicker(currentUser),
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _toggleRecording(currentUser),
                        icon: Icon(
                          _isRecording
                              ? Icons.stop_circle
                              : Icons.mic_none_rounded,
                          color: _isRecording
                              ? AppColors.errorRed
                              : AppColors.accentBlue,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: _isRecording
                                ? 'Recording voice message...'
                                : 'Type a message',
                            filled: true,
                            fillColor: AppColors.backgroundSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _sendTextMessage(currentUser),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      ElevatedButton(
                        onPressed: _isRecording
                            ? null
                            : () => _sendTextMessage(currentUser),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(14),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Text(
            'Unable to open this conversation.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isPlaying,
    this.onPlayVoice,
  });

  final MarketplaceChatMessage message;
  final bool isMe;
  final bool isPlaying;
  final VoidCallback? onPlayVoice;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColors.accentBlue : Colors.white;
    final textColor = isMe ? Colors.white : AppColors.primaryNavy;

    Widget content;
    switch (message.type) {
      case ChatMessageType.photo:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  message.mediaUrl!,
                  width: 220,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.content.trim().isNotEmpty &&
                message.content.trim() != ChatMessageType.photo.previewLabel)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s),
                child: Text(
                  message.content,
                  style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                ),
              ),
          ],
        );
      case ChatMessageType.voice:
        content = InkWell(
          onTap: onPlayVoice,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                color: textColor,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                isPlaying ? 'Stop voice note' : 'Play voice note',
                style: AppTextStyles.bodyMedium.copyWith(color: textColor),
              ),
            ],
          ),
        );
      case ChatMessageType.text:
        content = Text(
          message.content,
          style: AppTextStyles.bodyMedium.copyWith(color: textColor),
        );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryNavy.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            content,
            const SizedBox(height: 6),
            Text(
              message.timestamp == null
                  ? 'Sending...'
                  : timeago.format(message.timestamp!, locale: 'en_short'),
              style: AppTextStyles.caption.copyWith(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.84)
                    : AppColors.primaryNavy.withValues(alpha: 0.54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
