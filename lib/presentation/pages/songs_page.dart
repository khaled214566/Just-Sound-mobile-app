import 'package:flutter/material.dart';
import 'package:idgaf/core/models/audio_player.dart';
import 'package:idgaf/core/models/files_loader.dart';
import 'package:idgaf/core/models/permission.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final AudioService _audioService = AudioService();

  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;
  String _debugMessage = "Initializing...";
  Set<int> _favorites = {}; // Track favorite song indices

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    bool permissionGranted =
        await PermissionService.requestStoragePermissions();

    if (!permissionGranted) {
      setState(() {
        _debugMessage = "Storage permission denied";
        _isLoading = false;
      });
      return;
    }

    final songs = await SongLoader.loadSongs();

    setState(() {
      _songs = songs;
      _isLoading = false;
      _debugMessage = songs.isEmpty
          ? "No MP3 files found"
          : "Loaded ${songs.length} songs";
    });
  }

  Future<void> _playSong(int index) async {
    final song = _songs[index];
    await _audioService.play(song['filePath'], index);

    setState(() {});
  }

  void _toggleFavorite(int index) {
    setState(() {
      if (_favorites.contains(index)) {
        _favorites.remove(index);
      } else {
        _favorites.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Songs")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_debugMessage),
            ],
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Songs")),
        body: Center(child: Text(_debugMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("${_songs.length} songs")),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          final isPlaying = _audioService.currentIndex == index;
          final isFavorite = _favorites.contains(index);

          return ListTile(
            // Song icon on the left
            leading: Icon(
              Icons.music_note,
              size: 28,
              color: Theme.of(context).primaryColor,
            ),
            // Title and artist in the center
            title: Text(
              song['title'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              "Unknown",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Play button and heart on the right
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (isPlaying) {
                      _audioService.pause();
                    } else {
                      _playSong(index);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => _toggleFavorite(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
