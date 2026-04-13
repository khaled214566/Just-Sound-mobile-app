import 'package:flutter/material.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
import 'package:idgaf/core/models/playlist.dart';
import 'package:idgaf/core/models/playlist_service.dart';
import 'package:idgaf/presentation/pages/playlist_detail.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late PlaylistService _playlistService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _playlistService = await PlaylistService.instance;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createPlaylistDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _playlistService.createPlaylist(result);
    }
  }

  Future<void> _deletePlaylist(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _playlistService.deletePlaylist(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Playlists'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createPlaylistDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Playlist>>(
        valueListenable: _playlistService.playlistsNotifier,
        builder: (context, playlists, _) {
          if (playlists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No playlists yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create one',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Dismissible(
                key: Key(playlist.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deletePlaylist(playlist.id),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(
                    Icons.playlist_play,
                    color: AppColors.lightBlue,
                  ),
                  title: Text(
                    playlist.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailPage(
                          playlist: playlist,
                          playlistService: _playlistService,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
