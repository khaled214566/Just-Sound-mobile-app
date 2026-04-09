import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _queue = [];
  int? currentIndex;

  // 🔥 Constructor (auto next when finished)
  AudioService() {
    _audioPlayer.playerStateStream.listen((state) {
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

    await _audioPlayer.stop();
    await _audioPlayer.setFilePath(path);
    await _audioPlayer.play();
  }

  // 🔥 Play from list (main entry)
  Future<void> playFromList(List<Map<String, dynamic>> songs, int index) async {
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

  // 🔥 Controls
  Future<void> pause() async => _audioPlayer.pause();
  Future<void> resume() async => _audioPlayer.play();

  void dispose() {
    _audioPlayer.dispose();
  }
}
