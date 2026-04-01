import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? currentIndex;

  Future<void> play(String path, int index) async {
    if (currentIndex != null && currentIndex != index) {
      await _audioPlayer.stop();
    }

    await _audioPlayer.setFilePath(path);
    await _audioPlayer.play();
    currentIndex = index;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
