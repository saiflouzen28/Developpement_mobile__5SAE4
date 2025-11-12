import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../../models/voice_comment_model.dart';

/// Voice Player Widget - Plays audio with waveform visualization
class VoicePlayerWidget extends StatefulWidget {
  final VoiceComment voiceComment;
  final bool isCompact;
  final VoidCallback? onPlayStateChanged;

  const VoicePlayerWidget({
    super.key,
    required this.voiceComment,
    this.isCompact = false,
    this.onPlayStateChanged,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  bool _isPlaying = false;
  int _currentPosition = 0; // in seconds
  Timer? _playTimer;
  late AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _duration = Duration(seconds: widget.voiceComment.duration);
    
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
        if (state == PlayerState.completed) {
          setState(() {
            _currentPosition = 0;
            _position = Duration.zero;
          });
        }
      }
    });
    
    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          _currentPosition = position.inSeconds;
        });
      }
    });
    
    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() async {
    try {
      final audioUrl = widget.voiceComment.audioUrl;
      print('🎵 Attempting to play audio from: $audioUrl');
      
      // Check if file exists
      final file = File(audioUrl);
      final exists = await file.exists();
      print('🎵 File exists: $exists');
      
      if (!exists) {
        throw Exception('Audio file not found at: $audioUrl');
      }
      
      // Play from file path (DeviceFileSource for local files)
      await _audioPlayer.play(DeviceFileSource(audioUrl));
      print('🎵 Playback started successfully');
      
      widget.onPlayStateChanged?.call();
      
    } catch (e) {
      print('❌ Playback Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot play audio: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _pause() async {
    await _audioPlayer.pause();
  }

  void _seek(double value) async {
    final position = Duration(seconds: (value * widget.voiceComment.duration).round());
    await _audioPlayer.seek(position);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getToneColor() {
    final hex = widget.voiceComment.toneColorHex;
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactPlayer();
    }
    return _buildFullPlayer();
  }

  Widget _buildCompactPlayer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getToneColor().withOpacity(0.1),
            _getToneColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getToneColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Play button
          InkWell(
            onTap: _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getToneColor(),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getToneColor().withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Waveform and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini waveform
                SizedBox(
                  height: 30,
                  child: CustomPaint(
                    painter: MiniWaveformPainter(
                      progress: _currentPosition / widget.voiceComment.duration,
                      color: _getToneColor(),
                    ),
                    size: const Size(double.infinity, 30),
                  ),
                ),
                const SizedBox(height: 4),
                // Time display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(_currentPosition),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.voiceComment.formattedDuration,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Tone emoji
          Text(
            widget.voiceComment.toneEmoji,
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getToneColor().withOpacity(0.15),
            _getToneColor().withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getToneColor().withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getToneColor().withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tone
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getToneColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.voiceComment.toneEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.voiceComment.tone?.toUpperCase() ?? 'VOICE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.mic,
                color: _getToneColor(),
                size: 20,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Large waveform
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: WaveformPainter(
                  progress: _currentPosition / widget.voiceComment.duration,
                  color: _getToneColor(),
                ),
                size: const Size(double.infinity, 60),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progress slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _getToneColor(),
              inactiveTrackColor: _getToneColor().withOpacity(0.2),
              thumbColor: _getToneColor(),
              overlayColor: _getToneColor().withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: (_currentPosition / widget.voiceComment.duration).clamp(0.0, 1.0),
              onChanged: _seek,
            ),
          ),
          
          // Time and controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_currentPosition),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getToneColor(),
                ),
              ),
              // Play button
              InkWell(
                onTap: _togglePlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getToneColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getToneColor().withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Text(
                widget.voiceComment.formattedDuration,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Painter for full waveform with progress
class WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  WaveformPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 40;
    final barWidth = size.width / (barCount * 2);
    final centerY = size.height / 2;
    
    // Generate pseudo-random waveform
    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2 + barWidth;
      final normalizedI = i / barCount;
      final height = size.height * (0.3 + 0.6 * (sin(normalizedI * 6.28 * 3).abs()));
      
      final paint = Paint()
        ..color = normalizedI <= progress ? color : color.withOpacity(0.3)
        ..strokeWidth = barWidth * 0.8
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Painter for compact mini waveform
class MiniWaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  MiniWaveformPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 25;
    final barWidth = size.width / (barCount * 1.5);
    final centerY = size.height / 2;
    
    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 1.5 + barWidth / 2;
      final normalizedI = i / barCount;
      final height = size.height * (0.4 + 0.5 * (sin(normalizedI * 6.28 * 2).abs()));
      
      final paint = Paint()
        ..color = normalizedI <= progress ? color : color.withOpacity(0.25)
        ..strokeWidth = barWidth * 0.7
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MiniWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
