class Song {
  final String title;
  final String artist;
  final String album;
  final num duration;
  final String filePath;
  final Timestamp releaseDate;

  Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.filePath,
    required this.releaseDate,
  });
}