import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _queue = [];
  int? currentIndex;
  bool _isPlaying = false;

  // 🔥 Constructor (auto next when finished)
  AudioService() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  // 🔥 Set queue
  void setQueue(List<Map<String, dynamic>> songs, int startIndex) {
    _queue = songs;
    currentIndex = startIndex;
  }

  // 🔥 Play current song
  Future<void> playCurrent() async {
    if (currentIndex == null || _queue.isEmpty) return;

    final song = _queue[currentIndex!];
    final path = song['filePath'];

    if (path == null) {
      print("ERROR: filePath is null → $song");
      return;
    }

    // Only load new file if path changed
    if (_audioPlayer.sequenceState?.currentSource?.tag != currentIndex) {
      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(path);
    }

    await _audioPlayer.play();
    _isPlaying = true;
  }

  // 🔥 Play from list (main entry) - FIXED: Check if already playing
  Future<void> playFromList(List<Map<String, dynamic>> songs, int index) async {
    // If clicking the same song that's already playing, toggle pause/play
    if (currentIndex == index && _isPlaying) {
      await pause();
      return;
    }

    // If clicking the same song that's paused, resume it
    if (currentIndex == index && !_isPlaying) {
      await resume();
      return;
    }

    // Otherwise, play the new song
    setQueue(songs, index);
    await playCurrent();
  }

  // 🔥 Next
  Future<void> playNext() async {
    if (currentIndex == null) return;

    if (currentIndex! < _queue.length - 1) {
      currentIndex = currentIndex! + 1;
      await playCurrent();
    }
  }

  // 🔥 Previous
  Future<void> playPrevious() async {
    if (currentIndex == null) return;

    if (currentIndex! > 0) {
      currentIndex = currentIndex! - 1;
      await playCurrent();
    }
  }

  // 🔥 Controls - FIXED: pause() now properly pauses
  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  // 🔥 Resume - FIXED: resume() continues from where it paused
  Future<void> resume() async {
    await _audioPlayer.play();
    _isPlaying = true;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
