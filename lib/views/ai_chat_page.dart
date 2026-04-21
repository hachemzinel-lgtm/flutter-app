import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/views/search_params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_application_1/providers/chat_controller.dart';
import 'package:flutter_application_1/providers/chat_session_provider.dart';
import 'package:flutter_application_1/views/chat_message.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

class _C {
  static const primary = Color(0xFF1A6BFF);
  static const primaryLight = Color(0xFF5A95FF);
  static const primarySurface = Color(0xFFEEF4FF);
  static const bg = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0D1B2A);
  static const textSecondary = Color(0xFF6B7A8D);
  static const userBubble = Color(0xFF1A6BFF);
  static const aiBubble = Colors.white;
  static const inputBg = Color(0xFFEFF2F7);
  static const error = Color(0xFFE53935);
  static const recordingRed = Color(0xFFFF3B30);
  static const chipBg = Color(0xFFE8F0FE);
  static const chipFg = Color(0xFF1557D6);
  static const divider = Color(0xFFE4E8EE);
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class AIChatPage extends ConsumerStatefulWidget {
  const AIChatPage({super.key});

  @override
  ConsumerState<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends ConsumerState<AIChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasText = false;

  late final AnimationController _recordPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _msgController.addListener(() {
      final has = _msgController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _recordPulse.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleSend() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    ref.read(chatControllerProvider.notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      ref
          .read(chatControllerProvider.notifier)
          .sendImageMessage(File(picked.path));
      Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          ref
              .read(chatControllerProvider.notifier)
              .sendVoiceMessage(File(path));
          Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final path =
              '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );
          setState(() => _isRecording = true);
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording failed — check microphone permission.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final messagesAsync = ref.watch(activeSessionMessagesProvider);

    ref.listen<ChatState>(chatControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: _C.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState();

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isFirst =
                        i == 0 || messages[i - 1].isUserMessage != msg.isUserMessage;
                    return _MessageBubble(
                      message: msg,
                      isFirst: isFirst,
                    );
                  },
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load messages\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _C.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          if (chatState.isLoading) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: _C.divider,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.primary, _C.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FixIt AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Home Repair Assistant',
                style: TextStyle(
                  fontSize: 11,
                  color: _C.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () =>
                ref.read(chatControllerProvider.notifier).startNewSession(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
            style: TextButton.styleFrom(
              foregroundColor: _C.primary,
              backgroundColor: _C.primarySurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.primary, _C.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.home_repair_service_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hi there! 👋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "I'm your home repair assistant.\nDescribe the problem, send a photo,\nor record a voice note.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: _C.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _buildSuggestionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      ('🔧', 'Leaking pipe'),
      ('💡', 'Flickering lights'),
      ('🪟', 'Broken window'),
      ('❄️', 'AC not cooling'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions
          .map(
            (s) => GestureDetector(
          onTap: () {
            _msgController.text = s.$2;
            _handleSend();
          },
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${s.$1} ${s.$2}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _C.textPrimary,
              ),
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _C.aiBubble,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(3, (i) {
                return _BouncingDot(delay: Duration(milliseconds: i * 150));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 8,
        start: 12,
        end: 12,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: _C.surface,
        border: const Border(top: BorderSide(color: _C.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image picker
          _InputIconButton(
            icon: Icons.image_outlined,
            onTap: _pickImage,
            tooltip: 'Send photo',
          ),
          const SizedBox(width: 4),
          // Voice recorder
          AnimatedBuilder(
            animation: _recordPulse,
            builder: (context, child) {
              return _InputIconButton(
                icon: _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                color: _isRecording
                    ? Color.lerp(
                  _C.recordingRed,
                  _C.recordingRed.withValues(alpha: 0.6),
                  _recordPulse.value,
                )!
                    : _C.primary,
                onTap: _toggleRecording,
                tooltip: _isRecording ? 'Stop recording' : 'Voice message',
              );
            },
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _C.inputBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _msgController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 15,
                  color: _C.textPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: _isRecording ? '● Recording…' : 'Ask FixIt AI…',
                  hintStyle: TextStyle(
                    color: _isRecording ? _C.recordingRed : _C.textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedScale(
            scale: _hasText ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _hasText ? _handleSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: _hasText
                      ? const LinearGradient(
                    colors: [_C.primary, _C.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : LinearGradient(
                    colors: [
                      _C.textSecondary.withValues(alpha: 0.25),
                      _C.textSecondary.withValues(alpha: 0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFirst;

  const _MessageBubble({required this.message, required this.isFirst});

  static const _categories = [
    'Plumbing', 'Electrical', 'Cleaning', 'Painting',
    'Carpentry', 'HVAC', 'Landscaping',
  ];

  String? _detectCategory() {
    final lower = message.content.toLowerCase();
    for (final cat in _categories) {
      if (lower.contains(cat.toLowerCase())) return cat;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUserMessage) return _buildUserBubble(context);
    return _buildAIBubble(context);
  }

  Widget _buildUserBubble(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        top: isFirst ? 8 : 2,
        left: MediaQuery.of(context).size.width * 0.18,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E75FF), Color(0xFF4B96FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIBubble(BuildContext context) {
    final category = _detectCategory();

    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        top: isFirst ? 8 : 2,
        right: MediaQuery.of(context).size.width * 0.1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirst)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: _C.primary,
                    child: Icon(Icons.auto_fix_high_rounded,
                        color: Colors.white, size: 12),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'FixIt AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _C.aiBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: _C.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                color: _C.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          if (category != null) ...[
            const SizedBox(height: 6),
            _CategoryChip(category: category),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Category chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  static const _icons = {
    'Plumbing': Icons.water_drop_outlined,
    'Electrical': Icons.bolt_outlined,
    'Cleaning': Icons.cleaning_services_outlined,
    'Painting': Icons.format_paint_outlined,
    'Carpentry': Icons.carpenter,
    'HVAC': Icons.air_outlined,
    'Landscaping': Icons.grass_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/search-results',
          extra: SearchParams(
            targetType: 'work_provider',
            presetCategory: category,
            radius: 10,
            verifiedOnly: false,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _C.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[category] ?? Icons.search_rounded,
              size: 15,
              color: _C.chipFg,
            ),
            const SizedBox(width: 6),
            Text(
              'Find $category pros nearby',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _C.chipFg,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: _C.chipFg),
          ],
        ),
      ),
    );
  }
}

// ─── Input icon button ────────────────────────────────────────────────────────

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String tooltip;

  const _InputIconButton({
    required this.icon,
    required this.onTap,
    this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _C.inputBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 22,
            color: color ?? _C.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Bouncing dot (typing indicator) ─────────────────────────────────────────

class _BouncingDot extends StatefulWidget {
  final Duration delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _anim =
  Tween<double>(begin: 0, end: -6).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: _C.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}