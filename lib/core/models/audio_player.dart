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
  /// Index of the currently active song in [_queue]. -1 means nothing loaded.
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(-1);

  /// True while the player is actively playing.
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  // ─── Queue ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _queue = [];

  /// Replace the queue without changing playback.
  void setQueue(List<Map<String, dynamic>> songs, int startIndex) {
    _queue = List<Map<String, dynamic>>.from(songs);
    currentIndex.value = startIndex.clamp(0, songs.length - 1);
  }

  // ─── Playback ─────────────────────────────────────────────────────────────

  /// Main entry point used by the song list.
  Future<void> playFromList(List<Map<String, dynamic>> songs, int index) async {
    // 💡 FIX: Check by length and path instead of List instance equality
    bool isSameQueue = _queue.length == songs.length && 
                       _queue.isNotEmpty && 
                       _queue[0]['filePath'] == songs[0]['filePath'];

    if (currentIndex.value == index && isSameQueue) {
      if (isPlaying.value) {
        await pause();
      } else {
        await resume();
      }
      return;
    }

    _queue = List<Map<String, dynamic>>.from(songs);
    currentIndex.value = index;
    await _playCurrent();
  }
 Future<void> _playCurrent() async {
    if (currentIndex.value < 0 || currentIndex.value >= _queue.length) return;

    final song = _queue[currentIndex.value];
    final path = song['filePath'] as String?;
    if (path == null) return;

    try {
      // Use try/catch because file loading can fail
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
      // isPlaying.value is updated automatically by the listener in constructor
    } catch (e) {
      debugPrint("Error loading audio: $e");
      playNext(); // Skip to next if this one fails
    }
  }

  // ─── Controls ─────────────────────────────────────────────────────────────

  Future<void> playNext() async {
    if (currentIndex.value < _queue.length - 1) {
      currentIndex.value++; // Incrementing ValueNotifier notifies UI
      await _playCurrent();
    } else {
      // Optional: Loop to beginning or stop
      await _audioPlayer.stop();
      currentIndex.value = -1; 
    }
  }

  Future<void> playPrevious() async {
    if (currentIndex.value > 0) {
      currentIndex.value = currentIndex.value - 1;
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

  // Exposed for widgets that need low-level stream access (e.g. seek bar).
  AudioPlayer get player => _audioPlayer;

  /// No-op kept for API compatibility — the singleton is never truly disposed.
  void dispose() {}
}
