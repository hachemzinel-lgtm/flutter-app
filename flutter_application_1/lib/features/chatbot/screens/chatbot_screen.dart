import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart' as prov;
import 'package:record/record.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

// ──────────────────────────────────────────────────────────────────────────
// Outer wrapper – owns the ChatProvider so the inner StatefulWidget can use
// context.read<ChatProvider>() in initState via a microtask
// ──────────────────────────────────────────────────────────────────────────

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return prov.ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: const _ChatbotView(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Inner view – has access to ChatProvider via context
// ──────────────────────────────────────────────────────────────────────────

class _ChatbotView extends StatefulWidget {
  const _ChatbotView();

  @override
  State<_ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<_ChatbotView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  String? _recordingPath;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  static const List<String> _suggestions = [
    '🚽 My toilet won\'t stop running',
    '💡 A light switch isn\'t working',
    '💧 Water leak under my sink',
    '🏗 My wall has cracks',
  ];

  @override
  void initState() {
    super.initState();
    // microtask ensures the ChangeNotifierProvider above is fully built
    Future.microtask(() {
      if (mounted) context.read<ChatProvider>().startNewConversation();
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Scroll ─────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Send text ───────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() {});
    await context.read<ChatProvider>().sendTextMessage(text);
    _scrollToBottom();
  }

  Future<void> _sendSuggestion(String text) async {
    await context.read<ChatProvider>().sendTextMessage(text);
    _scrollToBottom();
  }

  // ─── Image ──────────────────────────────────────────────────────────────

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F4FD),
                  child: Icon(Icons.camera_alt, color: AppColors.accentBlue),
                ),
                title: const Text('📷 Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F4FD),
                  child: Icon(Icons.photo_library, color: AppColors.accentBlue),
                ),
                title: const Text('🖼 Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Camera needs explicit permission; gallery uses the OS file picker (no manual permission needed)
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Camera permission denied. Please allow access in Settings.')),
        );
        return;
      }
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (picked == null || !mounted) return;

      await context.read<ChatProvider>().sendImageMessage(File(picked.path));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  // ─── Voice ──────────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordSeconds = 0;
      });
      if (path != null && mounted) {
        await context.read<ChatProvider>().sendVoiceMessage(File(path));
        _scrollToBottom();
      }
    } else {
      final status = await Permission.microphone.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied.')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    }
  }

  String _formatDuration(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FixIt AI 🔧',
              style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
            ),
            Text(
              'Home repair & maintenance assistant',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.softGray),
            ),
          ],
        ),
        actions: [
          prov.Consumer<ChatProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.softGray),
              tooltip: 'New conversation',
              onPressed: () {
                provider.startNewConversation();
                _textController.clear();
                setState(() {});
              },
            ),
          ),
        ],
      ),
      body: prov.Consumer<ChatProvider>(
        builder: (context, provider, _) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());

          return Column(
            children: [
              // ── Messages ────────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  itemCount: provider.messages.length +
                      // show chips only when only the welcome message exists
                      (provider.messages.length == 1 ? 1 : 0),
                  itemBuilder: (ctx, index) {
                    // Suggestion chips slot
                    if (provider.messages.length == 1 && index == 1) {
                      return _buildSuggestionChips(provider);
                    }
                    return ChatBubble(message: provider.messages[index]);
                  },
                ),
              ),

              // ── Typing indicator ─────────────────────────────────────────
              if (provider.isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _animatedDot(0),
                      _animatedDot(200),
                      _animatedDot(400),
                      const SizedBox(width: 8),
                      Text(
                        'FixIt AI is thinking...',
                        style: TextStyle(
                            color: AppColors.softGray, fontSize: 13),
                      ),
                    ],
                  ),
                ),

              // ── Input bar ────────────────────────────────────────────────
              _buildInputBar(provider),
            ],
          );
        },
      ),
    );
  }

  // ─── Suggestion chips ───────────────────────────────────────────────────

  Widget _buildSuggestionChips(ChatProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((s) {
          return ActionChip(
            label: Text(s,
                style: const TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            backgroundColor: Colors.white,
            side: BorderSide(
                color: AppColors.accentBlue.withValues(alpha: 0.35)),
            elevation: 1,
            shadowColor: Colors.black12,
            onPressed: () => _sendSuggestion(s),
          );
        }).toList(),
      ),
    );
  }

  // ─── Animated dot (typing indicator) ────────────────────────────────────

  Widget _animatedDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 700 + delayMs),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ─── Input bar ──────────────────────────────────────────────────────────

  Widget _buildInputBar(ChatProvider provider) {
    final canSend = _textController.text.trim().isNotEmpty &&
        !provider.isLoading &&
        !_isRecording;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 📷 Photo button
          _iconBtn(
            icon: Icons.camera_alt_outlined,
            onTap: provider.isLoading ? null : _showPhotoSourceSheet,
            active: false,
          ),
          const SizedBox(width: 6),

          // Text field / recording indicator
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(22),
                border: _isRecording
                    ? Border.all(color: Colors.red.withValues(alpha: 0.6))
                    : null,
              ),
              child: _isRecording
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              color: Colors.red, size: 10),
                          const SizedBox(width: 6),
                          Text(
                            '🔴 Recording...  ${_formatDuration(_recordSeconds)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF1C1C1E)),
                      decoration: const InputDecoration(
                        hintText: 'Describe your home issue...',
                        hintStyle: TextStyle(
                            color: Color(0xFFAAAAAA), fontSize: 14),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _sendText(),
                    ),
            ),
          ),
          const SizedBox(width: 6),

          // 🎤 Mic button
          _iconBtn(
            icon: _isRecording
                ? Icons.stop_rounded
                : Icons.mic_none_rounded,
            onTap: provider.isLoading ? null : _toggleRecording,
            active: _isRecording,
            activeColor: Colors.red,
          ),
          const SizedBox(width: 6),

          // ➤ Send button
          GestureDetector(
            onTap: canSend ? _sendText : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: canSend
                    ? AppColors.accentBlue
                    : const Color(0xFFCCCCCC),
                shape: BoxShape.circle,
              ),
              child: provider.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required bool active,
    Color activeColor = AppColors.accentBlue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : const Color(0xFFF2F2F7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: active ? activeColor : AppColors.softGray,
        ),
      ),
    );
  }
}
