import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

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

            try {
              final metadata = await readMetadata(file, getImage: true);

              Uint8List? art;
              if (metadata.pictures.isNotEmpty) {
                art = metadata.pictures.first.bytes;
              }

              songsList.add({
                'filePath': file.path,
                'fileName': fileName,
                'title': metadata.title ?? fileName.replaceAll('.mp3', ''),
                'artist': metadata.artist ?? 'Unknown Artist',
                'album': metadata.album ?? 'Unknown Album',
                'duration': metadata.duration?.inMilliseconds ?? 0,
                'artwork': art, // 👈 ADD THIS
              });
            } catch (e) {
              // fallback if metadata fails
              songsList.add({
                'filePath': file.path,
                'fileName': fileName,
                'title': fileName.replaceAll('.mp3', ''),
                'artist': 'Unknown Artist',
                'album': 'Unknown Album',
                'duration': 0,
                'artwork': null,
              });
            }
          }
        } catch (_) {}
      }
    }

    return songsList;
  }
}
