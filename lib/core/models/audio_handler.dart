import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Converts your song map into an [MediaItem] that audio_service understands.
MediaItem songMapToMediaItem(Map<String, dynamic> song) {
  return MediaItem(
    id: song['filePath'] as String,
    title: song['title'] ?? 'Unknown Title',
    artist: song['artist'] ?? 'Unknown Artist',
    album: song['album'] ?? 'Unknown Album',
    duration: song['duration'] != null
        ? Duration(milliseconds: song['duration'] as int)
        : null,
    // artwork bytes are passed via artUri workaround below
    extras: {'artwork': song['artwork']}, // Uint8List stored here
  );
}

class MusicAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MusicAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Configure audio session for music
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Forward just_audio state → audio_service state (drives the notification)
    _player.playbackEventStream.listen(_broadcastState);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  // ─── Playback controls (called by the notification buttons) ───────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final currentIndex = playbackState.value.queueIndex ?? -1;
    if (currentIndex < queue.value.length - 1) {
      await skipToQueueItem(currentIndex + 1);
    } else {
      await stop();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final currentIndex = playbackState.value.queueIndex ?? 0;
    if (currentIndex > 0) {
      await skipToQueueItem(currentIndex - 1);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    mediaItem.add(queue.value[index]);
    playbackState.add(playbackState.value.copyWith(queueIndex: index));
    await _loadAndPlay(queue.value[index].id); // id == filePath
  }

  // ─── Queue management ─────────────────────────────────────────────────────

  /// Called from your AudioService to load a new queue and start playing.
  Future<void> loadQueue(
    List<Map<String, dynamic>> songs,
    int startIndex,
  ) async {
    final items = songs.map(songMapToMediaItem).toList();
    queue.add(items);
    await skipToQueueItem(startIndex);
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  Future<void> _loadAndPlay(String filePath) async {
    try {
      await _player.setFilePath(filePath);
      await _player.play();
    } catch (e) {
      debugPrint('AudioHandler: error loading $filePath — $e');
      await skipToNext();
    }
  }

  /// Translates just_audio's event into audio_service's PlaybackState.
  /// This is what drives the notification miniplayer UI.
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2], // prev / play / next
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: playbackState.value.queueIndex,
      ),
    );
  }

  // Expose the raw player for your existing position/duration streams
  AudioPlayer get player => _player;
}
