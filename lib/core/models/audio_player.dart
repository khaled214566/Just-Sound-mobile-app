import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// A singleton [AudioService] so playback state is never lost across
/// widget rebuilds or navigation.
class AudioService {
  // ─── Singleton ────────────────────────────────────────────────────────────
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;
  AudioService._internal() {
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  // ─── Internal player ──────────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ─── State (observable so the UI can react) ───────────────────────────────
  /// File path of the currently active song. `null` means nothing loaded.
  final ValueNotifier<String?> currentFilePath = ValueNotifier<String?>(null);

  /// True while the player is actively playing.
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  /// 🔥 Holds the current playlist for the MiniPlayer
  final ValueNotifier<List<Map<String, dynamic>>> currentQueue = ValueNotifier(
    [],
  );

  // ─── Internal index for playback control ─────────────────────────────────
  int _currentIndex = -1;

  // ─── Queue ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _queue = [];

  /// Replace the queue. Automatically preserves the currently playing song
  /// by locating its new index (if it still exists in the new queue).
  void setQueue(List<Map<String, dynamic>> newQueue) {
    final String? playingPath = currentFilePath.value;

    _queue = List<Map<String, dynamic>>.from(newQueue);

    if (playingPath != null) {
      _currentIndex = _queue.indexWhere(
        (song) => song['filePath'] == playingPath,
      );
    } else {
      _currentIndex = -1;
    }

    // Update the file path notifier (handles the case where the song was removed)
    _syncFilePathFromIndex();

    // 🔥 Notify listeners about the new queue
    currentQueue.value = List.unmodifiable(_queue);
  }

  // ─── Playback ─────────────────────────────────────────────────────────────

  /// Main entry point used by the song list.
  Future<void> playFromList(List<Map<String, dynamic>> songs, int index) async {
    // Determine if we are tapping the currently playing song from the same queue
    final String? playingPath = currentFilePath.value;
    final bool isSameSong =
        playingPath != null &&
        index >= 0 &&
        index < songs.length &&
        songs[index]['filePath'] == playingPath;

    if (isSameSong) {
      // Toggle play/pause
      if (isPlaying.value) {
        await pause();
      } else {
        await resume();
      }
      return;
    }

    // New song or different queue
    _queue = List<Map<String, dynamic>>.from(songs);
    _currentIndex = index;
    _syncFilePathFromIndex();
    // 🔥 Update the queue notifier
    currentQueue.value = List.unmodifiable(_queue);
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    final song = _queue[_currentIndex];
    final path = song['filePath'] as String?;
    if (path == null) return;

    try {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading audio: $e");
      playNext(); // Skip to next if this one fails
    }
  }

  // ─── Controls ─────────────────────────────────────────────────────────────

  Future<void> playNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      _syncFilePathFromIndex();
      await _playCurrent();
    } else {
      await _audioPlayer.stop();
      _currentIndex = -1;
      currentFilePath.value = null;
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      _syncFilePathFromIndex();
      await _playCurrent();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    isPlaying.value = false;
  }

  Future<void> resume() async {
    await _audioPlayer.play();
    isPlaying.value = true;
  }

  /// Returns the current playback position.
  Future<Duration?> getPosition() async => _audioPlayer.position;

  /// Returns the total duration of the current track.
  Future<Duration?> getDuration() async => _audioPlayer.duration;

  /// Seeks to the given [position] in the current track.
  Future<void> seek(Duration position) async => _audioPlayer.seek(position);

  // Exposed for widgets that need low-level stream access (e.g. seek bar).
  AudioPlayer get player => _audioPlayer;

  // ─── Private helpers ──────────────────────────────────────────────────────
  void _syncFilePathFromIndex() {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      currentFilePath.value = _queue[_currentIndex]['filePath'] as String?;
    } else {
      currentFilePath.value = null;
    }
  }

  /// No-op kept for API compatibility — the singleton is never truly disposed.
  void dispose() {}
}
