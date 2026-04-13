import 'package:flutter/material.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
import 'package:idgaf/core/models/audio_player.dart';
import 'package:idgaf/core/models/playlist.dart';
import 'package:idgaf/core/models/playlist_service.dart';
import 'package:idgaf/core/models/files_loader.dart';
import 'package:idgaf/core/models/miniPlayer.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;
  final PlaylistService playlistService;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
    required this.playlistService,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final AudioService _audioService = AudioService();
  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final List<Map<String, dynamic>> loaded = [];
    for (final filePath in widget.playlist.songIds) {
      try {
        final metadata = await getSongMetadata(filePath);
        loaded.add(metadata);
      } catch (e) {
        debugPrint('Failed to load $filePath: $e');
      }
    }
    if (mounted) {
      setState(() {
        _songs = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _playSong(int index) async {
    await _audioService.playFromList(_songs, index);
  }

  Future<void> _removeSong(String filePath) async {
    await widget.playlistService.removeSongFromPlaylist(
      widget.playlist.id,
      filePath,
    );
    setState(() {
      _songs.removeWhere((s) => s['filePath'] == filePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkGrey,
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final controller = TextEditingController(
                text: widget.playlist.name,
              );
              final newName = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Rename Playlist'),
                  content: TextField(controller: controller, autofocus: true),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        final name = controller.text.trim();
                        if (name.isNotEmpty) Navigator.pop(ctx, name);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (newName != null) {
                await widget.playlistService.renamePlaylist(
                  widget.playlist.id,
                  newName,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_note, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No songs in this playlist',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Long‑press a song in the Songs tab to add it',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ValueListenableBuilder<String?>(
                    valueListenable: _audioService.currentFilePath,
                    builder: (context, playingPath, _) {
                      return ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          final bool isSelected =
                              playingPath == song['filePath'];

                          return Dismissible(
                            key: Key(song['filePath']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _removeSong(song['filePath']),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(
                                  left: 10,
                                  right: 4,
                                ),
                                onTap: () => _playSong(index),
                                shape: isSelected
                                    ? ContinuousRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: AppColors.lightBlue,
                                          width: 2,
                                        ),
                                      )
                                    : null,
                                leading: song['artwork'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          song['artwork'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white54,
                                        ),
                                      ),
                                title: Text(
                                  song['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.lightBlue
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  song['artist'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.lightBlue
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: isSelected,
                                selectedTileColor: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _audioService.currentQueue,
            builder: (context, queue, _) {
              if (queue.isEmpty) return const SizedBox.shrink();
              return MiniPlayer(songs: queue);
            },
          ),
        ],
      ),
    );
  }
}
