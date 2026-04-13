import 'package:flutter/material.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
import 'package:idgaf/core/models/playlist.dart';
import 'package:idgaf/core/models/playlist_service.dart';

class PlaylistDetailPage extends StatelessWidget {
  final Playlist playlist;
  final PlaylistService playlistService;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
    required this.playlistService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkGrey,
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final controller = TextEditingController(text: playlist.name);
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
                await playlistService.renamePlaylist(playlist.id, newName);
              }
            },
          ),
        ],
      ),
      body: playlist.songIds.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No songs in this playlist yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add songs from the Songs tab',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: playlist.songIds.length,
              itemBuilder: (context, index) {
                // We don't have the actual song map here because no song‑adding logic is implemented.
                // This will be filled later when you add the "add to playlist" feature.
                return ListTile(
                  leading: const Icon(
                    Icons.music_note,
                    color: AppColors.lightBlue,
                  ),
                  title: Text(
                    'Song ID: ${playlist.songIds[index]}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  subtitle: const Text(
                    '(metadata not loaded – add songs feature not yet implemented)',
                  ),
                );
              },
            ),
    );
  }
}
