import 'package:hive/hive.dart';
part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> songIds; // store videoId or filePath – we'll use videoId

  Playlist({required this.id, required this.name, this.songIds = const []});

  Playlist copyWith({String? name, List<String>? songIds}) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }
}
