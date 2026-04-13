import 'dart:async';
import 'package:flutter/material.dart';
import 'package:idgaf/core/models/audio_player.dart';

class MiniPlayer extends StatefulWidget {
  final List<Map<String, dynamic>> songs;

  const MiniPlayer({super.key, required this.songs});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioService _audioService = AudioService();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double? _dragValue; // holds slider value while user is dragging
  bool _isDragging = false;

  late final Timer _positionTimer;

  @override
  void initState() {
    super.initState();
    // Poll position every 500ms — lightweight and smooth enough for a mini player
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_isDragging && mounted) {
        _syncPosition();
      }
    });
  }

  @override
  void dispose() {
    _positionTimer.cancel();
    super.dispose();
  }

  Future<void> _syncPosition() async {
    final position = await _audioService.getPosition();
    final duration = await _audioService.getDuration();
    if (mounted) {
      setState(() {
        _position = position ?? Duration.zero;
        _duration = duration ?? Duration.zero;
      });
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _audioService.currentFilePath,
      builder: (context, filePath, _) {
        if (filePath == null) return const SizedBox.shrink();

        final currentSong = widget.songs.firstWhere(
          (song) => song['filePath'] == filePath,
          orElse: () => <String, dynamic>{},
        );

        if (currentSong.isEmpty) return const SizedBox.shrink();

        final double maxVal = _duration.inMilliseconds > 0
            ? _duration.inMilliseconds.toDouble()
            : 1.0;

        // Use drag value while scrubbing, otherwise use real position
        final double sliderValue = _isDragging
            ? (_dragValue ?? 0.0).clamp(0.0, maxVal)
            : _position.inMilliseconds.toDouble().clamp(0.0, maxVal);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Song info + controls row ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong['title'] ?? 'Unknown Title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong['artist'] ?? 'Unknown Artist',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () => _audioService.playPrevious(),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _audioService.isPlaying,
                    builder: (context, playing, _) {
                      return IconButton(
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          playing
                              ? _audioService.pause()
                              : _audioService.resume();
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () => _audioService.playNext(),
                  ),
                ],
              ),

              // --- Progress bar + timestamps ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Text(
                      // Show drag position while scrubbing for instant feedback
                      _isDragging
                          ? _formatDuration(
                              Duration(milliseconds: (_dragValue ?? 0).toInt()),
                            )
                          : _formatDuration(_position),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: const Color(0xff88D3EC),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                        ),
                        child: Slider(
                          min: 0.0,
                          max: maxVal,
                          value: sliderValue,
                          onChangeStart: (value) {
                            setState(() {
                              _isDragging = true;
                              _dragValue = value;
                            });
                          },
                          onChanged: (value) {
                            setState(() => _dragValue = value);
                          },
                          onChangeEnd: (value) async {
                            await _audioService.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                            setState(() {
                              _isDragging = false;
                              _dragValue = null;
                            });
                          },
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
