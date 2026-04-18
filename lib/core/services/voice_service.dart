import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // record 5.x uses `AudioRecorder`
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        _currentPath =
            '${tempDir.path}/voice_msg_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
          path: _currentPath!,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
    return false;
  }

  Future<String?> stopRecordingAndGetBase64() async {
    try {
      final path = await _recorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return base64Encode(bytes);
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
    return null;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
