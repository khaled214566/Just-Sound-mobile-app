import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:idgaf/core/models/playlist.dart';

class PlaylistService {
  static PlaylistService? _instance;
  late final Box<Playlist> _box;

  final ValueNotifier<List<Playlist>> playlistsNotifier = ValueNotifier([]);

  PlaylistService._();

  /// Singleton access – call once in `main()` after registering adapters.
  static Future<PlaylistService> get instance async {
    if (_instance != null) return _instance!;
    _instance = PlaylistService._();
    await _instance!._init();
    return _instance!;
  }

  Future<void> _init() async {
    _box = await Hive.openBox<Playlist>('playlists');
    _loadPlaylists();
    _box.listenable().addListener(_loadPlaylists);
  }

  void _loadPlaylists() {
    playlistsNotifier.value = _box.values.toList();
  }

  Future<void> createPlaylist(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final playlist = Playlist(id: id, name: name);
    await _box.put(id, playlist);
  }

  Future<void> deletePlaylist(String id) async {
    await _box.delete(id);
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final playlist = _box.get(id);
    if (playlist != null) {
      await _box.put(id, playlist.copyWith(name: newName));
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songFilePath) async {
    final playlist = _box.get(playlistId);
    if (playlist != null && !playlist.songIds.contains(songFilePath)) {
      final updated = playlist.copyWith(
        songIds: [...playlist.songIds, songFilePath],
      );
      await _box.put(playlistId, updated);
    }
  }

  Future<void> removeSongFromPlaylist(
    String playlistId,
    String songFilePath,
  ) async {
    final playlist = _box.get(playlistId);
    if (playlist != null) {
      final updated = playlist.copyWith(
        songIds: playlist.songIds.where((id) => id != songFilePath).toList(),
      );
      await _box.put(playlistId, updated);
    }
  }

  void dispose() {
    playlistsNotifier.dispose();
    _box.close();
    _instance = null;
  }
}
