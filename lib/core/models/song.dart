import 'dart:typed_data';

class Song {
  final String title;
  final String artist;
  final String album;
  final num duration;
  final String filePath;
  final num releaseDate;
  final Uint8List? artwork;

  Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.filePath,
    required this.releaseDate,
    this.artwork,
  });
}
