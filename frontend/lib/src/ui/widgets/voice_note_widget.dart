import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../services/voice_note_service.dart';
import '../theme/app_theme.dart';

// ── Recording Widget (Sender Side) ────────────────────────────────────────────

/// Full-width recording sheet that appears when the user long-presses the mic.
/// Shows animated waveform bars + elapsed time.
class VoiceNoteRecorderSheet extends StatefulWidget {
  final void Function(VoiceNoteResult result) onSend;
  final VoidCallback onCancel;

  const VoiceNoteRecorderSheet({
    required this.onSend,
    required this.onCancel,
    super.key,
  });

  @override
  State<VoiceNoteRecorderSheet> createState() => _VoiceNoteRecorderSheetState();
}

class _VoiceNoteRecorderSheetState extends State<VoiceNoteRecorderSheet>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  StreamSubscription<Duration>? _durationSub;
  Duration _elapsed = Duration.zero;
  bool _started = false;
  String _statusText = 'Starting…';

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _startRecording();
  }

  Future<void> _startRecording() async {
    final ok = await VoiceNoteService.startRecording();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _started = true;
        _statusText = 'Recording…';
      });
      _durationSub = VoiceNoteService.durationStream.listen((d) {
        if (mounted) setState(() => _elapsed = d);
      });
    } else {
      setState(() => _statusText = 'Microphone permission denied');
    }
  }

  Future<void> _handleSend() async {
    _durationSub?.cancel();
    final result = await VoiceNoteService.stopRecording();
    if (result != null) {
      widget.onSend(result);
    } else {
      widget.onCancel();
    }
  }

  Future<void> _handleCancel() async {
    _durationSub?.cancel();
    await VoiceNoteService.cancelRecording();
    widget.onCancel();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _durationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Status
          Text(
            _statusText,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),

          // Animated waveform
          _AnimatedWaveform(controller: _waveController, isRecording: _started),
          const SizedBox(height: 16),

          // Timer
          Text(
            VoiceNoteService.formatDuration(_elapsed),
            style: const TextStyle(
              color: AppTheme.electricCyan,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 28),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel
              GestureDetector(
                onTap: _handleCancel,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.errorRed, width: 1.5),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppTheme.errorRed, size: 24),
                ),
              ),

              // Send
              GestureDetector(
                onTap: _started ? _handleSend : null,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.electricCyan,
                        AppTheme.primaryBlue,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.electricCyan.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Animated waveform bars ─────────────────────────────────────────────────────

class _AnimatedWaveform extends StatelessWidget {
  final AnimationController controller;
  final bool isRecording;

  const _AnimatedWaveform({
    required this.controller,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(20, (i) {
            final phase = (controller.value * 2 * pi) + (i * 0.4);
            final height = isRecording
                ? 8.0 + sin(phase).abs() * 28.0
                : 8.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: i % 3 == 0
                      ? AppTheme.electricCyan
                      : AppTheme.primaryBlue.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Playback Widget (Receiver Side) ───────────────────────────────────────────

/// Compact playback bubble for received voice notes.
class VoiceNotePlayerWidget extends StatefulWidget {
  final String audioPath; // local file path or HTTP URL
  final Duration duration;
  final bool isSent;

  const VoiceNotePlayerWidget({
    required this.audioPath,
    required this.duration,
    required this.isSent,
    super.key,
  });

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _total = widget.duration;

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
        if (state == PlayerState.completed) {
          setState(() => _position = Duration.zero);
        }
      }
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      final path = widget.audioPath;
      if (path.startsWith('http')) {
        await _player.play(UrlSource(path));
      } else {
        await _player.play(DeviceFileSource(path));
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _total.inMilliseconds > 0 ? _position.inMilliseconds / _total.inMilliseconds : 0.0;
    final bubbleColor = widget.isSent
        ? AppTheme.primaryBlue.withOpacity(0.6)
        : AppTheme.surfaceDark;

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.electricCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppTheme.electricCyan,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Progress + duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: AppTheme.textMuted.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(
                      AppTheme.electricCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Time
                Text(
                  '${VoiceNoteService.formatDuration(_position)} / ${VoiceNoteService.formatDuration(_total)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),
          const Icon(Icons.mic, size: 14, color: AppTheme.electricCyan),
        ],
      ),
    );
  }
}
