import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:idgaf/core/configs/assets/app_vectors.dart';
import 'package:idgaf/core/models/search_delegate.dart';
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

  void _sortSongs(String option) {
    setState(() {
      switch (option) {
        case 'title':
          _songs.sort(
            (a, b) => (a['title'] as String).toLowerCase().compareTo(
              (b['title'] as String).toLowerCase(),
            ),
          );
          break;
        case 'artist':
          _songs.sort(
            (a, b) => (a['artist'] as String).toLowerCase().compareTo(
              (b['artist'] as String).toLowerCase(),
            ),
          );
          break;
        case 'date':
          _songs.sort(
            (a, b) => (b['downloadDate'] as DateTime).compareTo(
              a['downloadDate'] as DateTime,
            ),
          );
          break;
      }
    });
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
        appBar: AppBar(
          title: const Text("Just Sound"),
          automaticallyImplyLeading: false, //!
          actions: [],
        ),
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
        appBar: AppBar(
          title: const Text("Just Sound"),
          automaticallyImplyLeading: false,
          actions: [], //!
        ),
        body: Center(child: Text(_debugMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Just Sound"),
        automaticallyImplyLeading: false, //!
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: MySearchDelegate());
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              _sortSongs(value); // handle selection
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'title', child: Text('Sort by Title')),
              const PopupMenuItem(
                value: 'artist',
                child: Text('Sort by Artist'),
              ),
              const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          final isPlaying = _audioService.currentIndex == index;
          final isFavorite = _favorites.contains(index);

          return ListTile(
            onTap: () {
              if (isPlaying) {
                _audioService.pause();
              } else {
                _playSong(index);
              }
            },
            // Song icon on the left
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
                : SvgPicture.asset(AppVectors.songLogo, width: 50, height: 50),
            // Title and artist in the center
            title: Text(
              song['title'],
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song['artist'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Play button and heart on the right
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
