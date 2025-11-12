import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice Recorder Widget - Records audio with waveform visualization
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String audioPath, int duration) onRecordingComplete;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  Timer? _amplitudeTimer;
  final List<double> _waveformData = [];
  late AnimationController _pulseController;
  final _recorder = AudioRecorder();
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    print('🎤 START RECORDING CALLED');
    try {
      // Request microphone permission
      print('🎤 Requesting microphone permission...');
      final status = await Permission.microphone.request();
      print('🎤 Permission status: $status');
      
      if (!status.isGranted) {
        print('❌ Microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record voice comments'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Check if recorder has permission
      if (!await _recorder.hasPermission()) {
        print('❌ No recording permission from recorder');
        return;
      }
      
      print('✅ Permission granted, starting recording...');
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _audioPath!,
      );
      
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _waveformData.clear();
      });

      // Start duration timer
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted) {
          setState(() {
            _recordDuration += 100;
          });
        }
      });
      
      // Start amplitude monitoring for waveform
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        final amplitude = await _recorder.getAmplitude();
        if (mounted) {
          setState(() {
            // Normalize amplitude to 0-1 range
            final normalizedAmplitude = (amplitude.current + 50) / 50;
            _waveformData.add(normalizedAmplitude.clamp(0.1, 1.0));
            if (_waveformData.length > 50) {
              _waveformData.removeAt(0);
            }
          });
        }
      });
      
    } catch (e) {
      print('❌ Recording Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    print('🎤 STOP RECORDING CALLED');
    try {
      _timer?.cancel();
      _amplitudeTimer?.cancel();
      
      // Stop recording
      print('🎤 Stopping recorder...');
      final path = await _recorder.stop();
      print('🎤 Recorder stopped, path: $path');
      
      if (path != null && path.isNotEmpty) {
        final duration = (_recordDuration / 1000).round();
        print('✅ Recording saved to: $path, Duration: ${duration}s');
        
        // Verify file exists
        final file = File(path);
        final exists = await file.exists();
        final fileSize = exists ? await file.length() : 0;
        print('✅ File exists: $exists, Size: $fileSize bytes');
        
        if (!exists || fileSize == 0) {
          throw Exception('Recording file is empty or does not exist');
        }
        
        print('🎤 Calling onRecordingComplete callback...');
        widget.onRecordingComplete(path, duration);
        print('🎤 Callback completed');
      
      } else {
        print('❌ No recording path returned');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save recording'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
    } catch (e) {
      print('❌ Stop Recording Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    await _recorder.stop();
    widget.onCancel();
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRecording ? 'Recording...' : 'Voice Comment',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelRecording,
                color: Colors.grey[600],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Waveform visualization
          if (_isRecording)
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: WaveformPainter(
                    waveformData: _waveformData,
                    color: Colors.deepPurple,
                  ),
                  size: Size.infinite,
                ),
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.deepPurple.withOpacity(0.3),
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to start recording',
                      style: TextStyle(
                        color: Colors.deepPurple.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Duration display
          Text(
            _formatDuration(_recordDuration),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _isRecording ? Colors.red : Colors.deepPurple,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // Cancel button
                ElevatedButton.icon(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Stop & Send button
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else
                // Start recording button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: ElevatedButton.icon(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.mic, size: 28),
                        label: const Text(
                          'Start Recording',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Info text
          Text(
            _isRecording 
                ? '🎤 Speak clearly into your microphone'
                : '💡 Voice comments are auto-transcribed and tagged',
            style: TextStyle(
              fontSize: 12,
              color: Colors.deepPurple.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;

  WaveformPainter({
    required this.waveformData,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = waveformData[i] * size.height * 0.8;
      
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData;
  }
}
