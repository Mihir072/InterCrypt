import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// VoiceNoteService — Record and provide voice notes for chat.
///
/// Uses the `record` package for audio capture.
/// Saves recordings as `.m4a` files in the temporary directory.
class VoiceNoteService {
  VoiceNoteService._();

  static final AudioRecorder _recorder = AudioRecorder();

  static bool _isRecording = false;
  static String? _currentRecordingPath;
  static DateTime? _recordingStartTime;
  static Timer? _durationTimer;
  static Duration _elapsed = Duration.zero;

  static final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  /// Stream of elapsed recording duration (ticks every second).
  static Stream<Duration> get durationStream => _durationController.stream;

  static bool get isRecording => _isRecording;
  static Duration get elapsed => _elapsed;

  /// Start recording a voice note.
  /// Returns true if recording started successfully.
  static Future<bool> startRecording() async {
    if (_isRecording) return false;
    if (kIsWeb) {
      debugPrint('VoiceNoteService: recording not supported on web');
      return false;
    }

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('VoiceNoteService: microphone permission denied');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${tempDir.path}/$fileName';

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _elapsed = Duration.zero;

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsed = DateTime.now().difference(_recordingStartTime!);
        _durationController.add(_elapsed);
      });

      debugPrint('VoiceNoteService: started recording → $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('VoiceNoteService: startRecording error — $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the path to the audio file.
  /// Returns null if recording was under 1 second (accidental tap).
  static Future<VoiceNoteResult?> stopRecording() async {
    if (!_isRecording) return null;

    _durationTimer?.cancel();
    _durationTimer = null;

    try {
      await _recorder.stop();
      _isRecording = false;

      final finalElapsed = _elapsed;
      final path = _currentRecordingPath;

      _currentRecordingPath = null;
      _elapsed = Duration.zero;

      // Discard very short clips (< 1 second — accidental taps)
      if (finalElapsed.inMilliseconds < 800 || path == null) {
        debugPrint('VoiceNoteService: recording too short, discarding');
        if (path != null) {
          try {
            await File(path).delete();
          } catch (_) {}
        }
        return null;
      }

      final file = File(path);
      final size = await file.length();

      debugPrint(
          'VoiceNoteService: recording stopped — ${finalElapsed.inSeconds}s, ${size}B');

      return VoiceNoteResult(
        filePath: path,
        duration: finalElapsed,
        fileSizeBytes: size,
      );
    } catch (e) {
      _isRecording = false;
      debugPrint('VoiceNoteService: stopRecording error — $e');
      return null;
    }
  }

  /// Cancel recording without saving.
  static Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _durationTimer?.cancel();
    _durationTimer = null;

    try {
      await _recorder.cancel();
    } catch (_) {
      await _recorder.stop();
    }

    _isRecording = false;
    _elapsed = Duration.zero;

    if (_currentRecordingPath != null) {
      try {
        await File(_currentRecordingPath!).delete();
      } catch (_) {}
      _currentRecordingPath = null;
    }
  }

  /// Format a duration as m:ss.
  static String formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Dispose resources (call on app close).
  static void dispose() {
    _durationTimer?.cancel();
    _durationController.close();
    _recorder.dispose();
  }
}

/// Result returned by [VoiceNoteService.stopRecording].
class VoiceNoteResult {
  final String filePath;
  final Duration duration;
  final int fileSizeBytes;

  const VoiceNoteResult({
    required this.filePath,
    required this.duration,
    required this.fileSizeBytes,
  });
}
