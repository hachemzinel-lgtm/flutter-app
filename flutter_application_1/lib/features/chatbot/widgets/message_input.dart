import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/voice_service.dart';

class MessageInput extends StatefulWidget {
  final Future<void> Function(String text, {String? imageBase64, String? audioBase64}) onSend;

  const MessageInput({super.key, required this.onSend});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImageService _imageService = ImageService();
  final VoiceService _voiceService = VoiceService();
  
  String? _selectedImageBase64;
  String? _recordedAudioBase64;
  
  bool _isSending = false;
  
  // Voice Recording Config
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImageBase64 == null && _recordedAudioBase64 == null) return;
    if (_isRecording) return; // Wait to finish recording

    setState(() {
      _isSending = true;
    });

    await widget.onSend(text, imageBase64: _selectedImageBase64, audioBase64: _recordedAudioBase64);

    if (mounted) {
      setState(() {
        _controller.clear();
        _selectedImageBase64 = null;
        _recordedAudioBase64 = null;
        _isSending = false;
      });
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final base64Str = fromCamera 
        ? await _imageService.takeCameraPhoto()
        : await _imageService.selectFromGallery();
        
    if (base64Str != null && mounted) {
      setState(() {
        _selectedImageBase64 = base64Str;
      });
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      final base64String = await _voiceService.stopRecordingAndGetBase64();
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordedAudioBase64 = base64String;
        });
      }
    } else {
      bool available = await _voiceService.startRecording();
      if (available) {
        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordDuration = 0;
            _recordedAudioBase64 = null;
          });
        }
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) setState(() => _recordDuration++);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access microphone.')),
          );
        }
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: AppSpacing.m,
        right: AppSpacing.m,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Previews Stack
          if (_selectedImageBase64 != null)
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(_selectedImageBase64!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImageBase64 = null),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          
          if (_recordedAudioBase64 != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text('Voice message recorded', style: TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _recordedAudioBase64 = null),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _actionButton(Icons.camera_alt, () => _pickImage(true), AppColors.accentBlue, Colors.white),
              const SizedBox(width: 8),
              _actionButton(Icons.image, () => _pickImage(false), AppColors.accentBlue, Colors.white),
              const SizedBox(width: 8),
              // Mic Button
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  height: 36,
                  width: 36,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red.withValues(alpha: 0.1) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_circle : Icons.mic, 
                    color: _isRecording ? const Color(0xFFFF3B30) : AppColors.accentBlue, 
                    size: 24
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Text Field / Recording Indicator
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _isRecording ? const Color(0xFFFF3B30).withValues(alpha: 0.5) : const Color(0xFFE5E5EA)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isRecording
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mic, color: Color(0xFFFF3B30), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Recording...  ${_formatDuration(_recordDuration)}",
                              style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: TextStyle(
                            color: Color(0xFFCCCCCC), 
                            fontSize: 14,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() {}),
                      ),
                ),
              ),
              const SizedBox(width: 8),
              // Send Button
              GestureDetector(
                onTap: ((_controller.text.trim().isNotEmpty || _selectedImageBase64 != null || _recordedAudioBase64 != null) && !_isSending && !_isRecording)
                    ? _handleSend
                    : null,
                child: Container(
                  height: 40,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: ((_controller.text.trim().isNotEmpty || _selectedImageBase64 != null || _recordedAudioBase64 != null) && !_isRecording) 
                        ? AppColors.accentBlue 
                        : const Color(0xFFCCCCCC),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending 
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap, Color iconColor, Color bgColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
