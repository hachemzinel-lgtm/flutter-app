import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? otherName;
  const ChatScreen({super.key, required this.conversationId, this.otherName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      final user = ref.read(authStateProvider).value;
      final userDoc = ref.read(currentUserDocProvider).value;
      if (user == null || userDoc == null) return;

      await ref.read(chatServiceProvider).sendMediaMessage(
        conversationId: widget.conversationId,
        senderId: user.uid,
        senderName: userDoc.name,
        file: File(pickedFile.path),
        type: 'photo',
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        final user = ref.read(authStateProvider).value;
        final userDoc = ref.read(currentUserDocProvider).value;
        if (user == null || userDoc == null) return;

        await ref.read(chatServiceProvider).sendMediaMessage(
          conversationId: widget.conversationId,
          senderId: user.uid,
          senderName: userDoc.name,
          file: File(path),
          type: 'voice',
        );
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final userDoc = ref.watch(currentUserDocProvider).value;
    if (user == null || userDoc == null) return const Center(child: CircularProgressIndicator());

    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final chatService = ref.read(chatServiceProvider);

    final currentUser = ChatUser(
      id: user.uid,
      firstName: userDoc.name,
      profileImage: userDoc.photoUrl,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName ?? 'Chat', style: AppTextStyles.headingSmall),
            Text(_isRecording ? 'Recording...' : 'Online', 
                style: AppTextStyles.caption.copyWith(color: _isRecording ? Colors.red : AppColors.availableGreen)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border_rounded, color: AppColors.starGold),
            tooltip: 'Rate this provider',
            onPressed: () {
              // Extract other user's ID from conversationId
              final myUid = ref.read(authServiceProvider).currentUser?.uid;
              if (myUid == null) return;
              final parts = widget.conversationId.split('_');
              final otherUid = parts[0] == myUid ? parts[1] : parts[0];
              context.push('/rate-service/$otherUid');
            },
          ),
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: messagesAsync.when(
        data: (snapshot) {
          final messages = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ChatMessage(
              user: ChatUser(id: data['senderId'], firstName: data['senderName'] ?? 'User'),
              text: data['text'] ?? '',
              medias: data['mediaURL'] != null ? [
                ChatMedia(url: data['mediaURL'], fileName: 'media', type: data['type'] == 'photo' ? MediaType.image : MediaType.video)
              ] : [],
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();

          return DashChat(
            currentUser: currentUser,
            onSend: (ChatMessage message) {
              chatService.sendMessage(widget.conversationId, {
                'text': message.text,
                'senderId': user.uid,
                'senderName': userDoc.name,
              });
            },
            messages: messages,
            messageOptions: MessageOptions(
              showOtherUsersAvatar: true,
              showTime: true,
              containerColor: AppColors.accentBlue,
              currentUserContainerColor: AppColors.accentBlue,
            ),
            inputOptions: InputOptions(
              leading: [
                IconButton(
                  icon: const Icon(Icons.image, color: AppColors.accentBlue),
                  onPressed: _sendImage,
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, color: _isRecording ? Colors.red : AppColors.accentBlue),
                  onPressed: _toggleRecording,
                ),
              ],
              inputDecoration: InputDecoration(
                hintText: 'Type a message...',
                fillColor: AppColors.softGray.withOpacity(0.05),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
