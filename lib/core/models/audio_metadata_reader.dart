import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'dart:typed_data';

Future<Uint8List?> getAlbumArt(String path) async {
  final metadata = await readMetadata(File(path), getImage: true);

  if (metadata.pictures.isNotEmpty) {
    return metadata.pictures.first.bytes;
  }

  return null;
}