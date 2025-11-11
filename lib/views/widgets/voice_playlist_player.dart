import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../../models/voice_comment_model.dart';

/// Voice Playlist Player - "Play All" podcast mode
class VoicePlaylistPlayer extends StatefulWidget {
  final List<VoicePlaylistItem> playlist;
  final VoidCallback onClose;

  const VoicePlaylistPlayer({
    super.key,
    required this.playlist,
    required this.onClose,
  });

  @override
  State<VoicePlaylistPlayer> createState() => _VoicePlaylistPlayerState();
}

class _VoicePlaylistPlayerState extends State<VoicePlaylistPlayer> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPlaying = false;
  int _currentPosition = 0;
  Timer? _playTimer;
  late AnimationController _rotationController;
  late AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _audioPlayer = AudioPlayer();
    
    // Listen to player state
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.playing) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
          }
        });
        if (state == PlayerState.completed) {
          _playNext();
        }
      }
    });
    
    // Listen to position
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          _currentPosition = position.inSeconds;
        });
      }
    });
    
    // Listen to duration
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    
    _autoPlay();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _rotationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _autoPlay() {
    _play();
  }

  void _play() async {
    if (widget.playlist.isEmpty) return;
    
    try {
      final audioUrl = widget.playlist[_currentIndex].voiceComment.audioUrl;
      print('🎵 Playlist playing: $audioUrl');
      await _audioPlayer.play(DeviceFileSource(audioUrl));
    } catch (e) {
      print('❌ Playlist playback error: $e');
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _playNext() async {
    if (_currentIndex < widget.playlist.length - 1) {
      await _audioPlayer.stop();
      setState(() {
        _currentIndex++;
        _currentPosition = 0;
      });
      _play();
    } else {
      await _pause();
      setState(() => _currentPosition = 0);
    }
  }

  void _playPrevious() async {
    if (_currentIndex > 0) {
      await _audioPlayer.stop();
      setState(() {
        _currentIndex--;
        _currentPosition = 0;
      });
      _play();
    }
  }

  void _selectTrack(int index) {
    setState(() {
      _currentIndex = index;
      _currentPosition = 0;
    });
    if (_isPlaying) {
      _playTimer?.cancel();
      _play();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getTotalDuration() {
    int total = 0;
    for (final item in widget.playlist) {
      total += item.voiceComment.duration;
    }
    return _formatTime(total);
  }

  Color _getCurrentColor() {
    final hex = widget.playlist[_currentIndex].voiceComment.toneColorHex;
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playlist.isEmpty) {
      return const Center(
        child: Text('No voice comments to play'),
      );
    }

    final currentItem = widget.playlist[_currentIndex];
    final currentVoice = currentItem.voiceComment;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCurrentColor().withOpacity(0.15),
            _getCurrentColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎙️ Discussion Podcast',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.playlist.length} voice comments • ${_getTotalDuration()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCurrentColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.playlist.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getCurrentColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main player area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Album art / Waveform visualization
                  RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _getCurrentColor(),
                            _getCurrentColor().withOpacity(0.6),
                            _getCurrentColor().withOpacity(0.3),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getCurrentColor().withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.podcasts,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Current track info
                  Text(
                    currentItem.displayTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Tone badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCurrentColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentVoice.toneEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentVoice.tone?.toUpperCase() ?? 'VOICE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getCurrentColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress bar
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: _getCurrentColor(),
                          inactiveTrackColor: _getCurrentColor().withOpacity(0.2),
                          thumbColor: _getCurrentColor(),
                          overlayColor: _getCurrentColor().withOpacity(0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: (_currentPosition / currentVoice.duration).clamp(0.0, 1.0),
                          onChanged: (value) {
                            setState(() {
                              _currentPosition = (value * currentVoice.duration).round();
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(_currentPosition),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _getCurrentColor(),
                              ),
                            ),
                            Text(
                              currentVoice.formattedDuration,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous button
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 48,
                        color: _currentIndex > 0 ? _getCurrentColor() : Colors.grey,
                        onPressed: _currentIndex > 0 ? _playPrevious : null,
                      ),

                      const SizedBox(width: 20),

                      // Play/Pause button
                      InkWell(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _getCurrentColor(),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getCurrentColor().withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Next button
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 48,
                        color: _currentIndex < widget.playlist.length - 1 
                            ? _getCurrentColor() 
                            : Colors.grey,
                        onPressed: _currentIndex < widget.playlist.length - 1 
                            ? _playNext 
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Playlist
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.queue_music_rounded,
                                color: _getCurrentColor(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Playlist',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getCurrentColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.playlist.length,
                          itemBuilder: (context, index) {
                            final item = widget.playlist[index];
                            final isPlaying = index == _currentIndex;
                            final itemColor = Color(
                              int.parse(item.voiceComment.toneColorHex.substring(1), radix: 16) + 0xFF000000,
                            );

                            return InkWell(
                              onTap: () => _selectTrack(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: isPlaying ? itemColor.withOpacity(0.1) : null,
                                child: Row(
                                  children: [
                                    // Track number or playing indicator
                                    SizedBox(
                                      width: 30,
                                      child: isPlaying
                                          ? Icon(
                                              Icons.equalizer_rounded,
                                              color: itemColor,
                                              size: 20,
                                            )
                                          : Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.displayTitle,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                                              color: isPlaying ? itemColor : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.voiceComment.toneEmoji} ${item.voiceComment.formattedDuration}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Tags preview
                                    if (item.voiceComment.extractedTags.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: itemColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.voiceComment.extractedTags.first,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: itemColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
