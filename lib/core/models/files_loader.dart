import 'dart:io';

class SongLoader {
  static Future<List<Map<String, dynamic>>> loadSongs() async {
    List<Map<String, dynamic>> songsList = [];

    final dirsToSearch = [
      "/storage/emulated/0/Music",
      "/storage/emulated/0/Download",
      "/sdcard/Music",
      "/sdcard/Download",
    ];

    for (final dirPath in dirsToSearch) {
      final dir = Directory(dirPath);

      if (dir.existsSync()) {
        try {
          final files = dir
              .listSync(recursive: false)
              .whereType<File>()
              .where((file) => file.path.toLowerCase().endsWith('.mp3'))
              .toList();

          for (var file in files) {
            final fileName = file.path.split('/').last;
            final title = fileName.replaceAll('.mp3', '');

            songsList.add({
              'filePath': file.path,
              'fileName': fileName,
              'title': title,
              'artist': 'Unknown Artist',
              'album': 'Unknown Album',
              'duration': 0,
            });
          }
        } catch (_) {}
      }
    }

    return songsList;
  }
}
