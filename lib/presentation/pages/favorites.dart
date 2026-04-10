import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idgaf/core/models/audio_player.dart';
import 'package:idgaf/core/models/favorites_service.dart';
import 'package:idgaf/presentation/choose_mode/bloc/theme_cubit.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final AudioService _audioService = AudioService();
  final FavoritesService _favoritesService = FavoritesService();

  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    // 🔥 Listen to changes in the currently playing song
    _audioService.currentFilePath.addListener(_onAudioStateChanged);
    _audioService.isPlaying.addListener(_onAudioStateChanged);
  }

  @override
  void dispose() {
    _audioService.currentFilePath.removeListener(_onAudioStateChanged);
    _audioService.isPlaying.removeListener(_onAudioStateChanged);
    // No need to call _audioService.dispose() – it's a singleton
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  // 🔥 Load all favorites from database
  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getAllFavorites();

    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  // 🔥 Play song from favorites
  Future<void> _playSong(int index) async {
    await _audioService.playFromList(_favorites, index);
  }

  // 🔥 Remove from favorites
  Future<void> _removeFavorite(int index) async {
    final filePath = _favorites[index]['filePath'];

    await _favoritesService.removeFavorite(filePath);

    setState(() {
      _favorites.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Favorites"),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_favorites.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Favorites"),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'No favorites yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Clear all'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear all favorites?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _favoritesService.clearAllFavorites();
                    setState(() {
                      _favorites.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final song = _favorites[index];

          // 🔥 Compare file path instead of index
          final String? playingPath = _audioService.currentFilePath.value;
          final bool isSelected =
              playingPath != null && playingPath == song['filePath'];

          return ListTile(
            onTap: () {
              _playSong(index);
            },

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
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                      ),
                    ),
                  ),

            title: Text(
              song['title'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song['artist'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _removeFavorite(index),
            ),

            selected: isSelected,
            selectedTileColor: Colors.grey[850],
          );
        },
      ),
    );
  }
}
