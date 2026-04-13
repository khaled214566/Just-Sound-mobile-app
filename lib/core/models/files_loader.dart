import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

Future<Map<String, dynamic>> getSongMetadata(String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('File not found: $filePath');
  }

  final fileName = filePath.split('/').last;
  final ext = fileName.contains('.')
      ? fileName.substring(fileName.lastIndexOf('.'))
      : '';
  final titleFallback = ext.isNotEmpty
      ? fileName.substring(0, fileName.length - ext.length)
      : fileName;

  try {
    final metadata = await readMetadata(file, getImage: true);
    Uint8List? art;
    if (metadata.pictures.isNotEmpty) {
      art = metadata.pictures.first.bytes;
    }

    return {
      'filePath': filePath,
      'fileName': fileName,
      'title': metadata.title ?? titleFallback,
      'artist': metadata.artist ?? 'Unknown Artist',
      'album': metadata.album ?? 'Unknown Album',
      'duration': metadata.duration?.inMilliseconds ?? 0,
      'artwork': art,
      'downloadDate': DateTime.fromMillisecondsSinceEpoch(
        file.lastModifiedSync().millisecondsSinceEpoch,
      ),
    };
  } catch (_) {
    // Fallback if metadata reading fails
    return {
      'filePath': filePath,
      'fileName': fileName,
      'title': titleFallback,
      'artist': 'Unknown Artist',
      'album': 'Unknown Album',
      'duration': 0,
      'artwork': null,
      'downloadDate': DateTime.fromMillisecondsSinceEpoch(
        file.lastModifiedSync().millisecondsSinceEpoch,
      ),
    };
  }
}

class SongLoader {
  /// Directories scanned for local audio files.
  /// Must include [DownloadManager.saveDirectory] so downloaded tracks appear.
  static const List<String> dirsToSearch = [
    '/storage/emulated/0/Download',
    // '/storage/emulated/0/Music',
    // '/sdcard/Download',
  ];

  /// Audio extensions to include.
  static const List<String> _extensions = ['.mp3', '.m4a'];

  static Future<List<Map<String, dynamic>>> loadSongs() async {
    final List<Map<String, dynamic>> songsList = [];

    for (final dirPath in dirsToSearch) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      try {
        final files = dir.listSync(recursive: false).whereType<File>().where((
          file,
        ) {
          final lower = file.path.toLowerCase();
          return _extensions.any((ext) => lower.endsWith(ext));
        }).toList();

        for (final file in files) {
          final fileName = file.path.split('/').last;
          final ext = _extensions.firstWhere(
            (e) => fileName.toLowerCase().endsWith(e),
            orElse: () => '',
          );
          final titleFallback = ext.isNotEmpty
              ? fileName.substring(0, fileName.length - ext.length)
              : fileName;

          try {
            final metadata = await readMetadata(file, getImage: true);

            Uint8List? art;
            if (metadata.pictures.isNotEmpty) {
              art = metadata.pictures.first.bytes;
            }

            songsList.add({
              'filePath': file.path,
              'fileName': fileName,
              'title': metadata.title ?? titleFallback,
              'artist': metadata.artist ?? 'Unknown Artist',
              'album': metadata.album ?? 'Unknown Album',
              'duration': metadata.duration?.inMilliseconds ?? 0,
              'artwork': art,
              'downloadDate': DateTime.fromMillisecondsSinceEpoch(
                file.lastModifiedSync().millisecondsSinceEpoch,
              ),
            });
          } catch (_) {
            // Metadata read failed — still include the file with fallback values
            songsList.add({
              'filePath': file.path,
              'fileName': fileName,
              'title': titleFallback,
              'artist': 'Unknown Artist',
              'album': 'Unknown Album',
              'duration': 0,
              'artwork': null,
              'downloadDate': DateTime.fromMillisecondsSinceEpoch(
                file.lastModifiedSync().millisecondsSinceEpoch,
              ),
            });
          }
        }
      } catch (_) {
        // Directory read failed — skip silently
      }
    }

    return songsList;
  }
}
