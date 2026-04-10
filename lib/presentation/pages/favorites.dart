import 'package:flutter/material.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
import 'package:idgaf/core/models/audio_player.dart';
import 'package:idgaf/core/models/favorites_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final AudioService _audioService = AudioService();
  final FavoritesService _favoritesService = FavoritesService();

  // Cached full list of favorite songs (including artwork)
  List<Map<String, dynamic>> _cachedFavorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    _audioService.currentFilePath.addListener(_onAudioStateChanged);
    _audioService.isPlaying.addListener(_onAudioStateChanged);
  }

  @override
  void dispose() {
    _audioService.currentFilePath.removeListener(_onAudioStateChanged);
    _audioService.isPlaying.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getAllFavorites();
    if (mounted) {
      setState(() {
        _cachedFavorites = favorites;
        _isLoading = false;
      });
    }
  }

  // Play a song from the filtered list – we pass the actual song item to the audio service.
  Future<void> _playSong(Map<String, dynamic> song) async {
    // Find the index of this song in the cached full list for playback queue
    final index = _cachedFavorites.indexWhere(
      (s) => s['filePath'] == song['filePath'],
    );
    if (index != -1) {
      await _audioService.playFromList(_cachedFavorites, index);
    }
  }

  // Remove favorite using filePath to avoid index confusion
  Future<void> _removeFavorite(String filePath) async {
    // Optimistic UI update: remove from cached list immediately
    setState(() {
      _cachedFavorites.removeWhere((song) => song['filePath'] == filePath);
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await _favoritesService.removeFavorite(filePath);
      // The notifier will update automatically, but our cached list already
      // reflects the change, so we don't need to reload.
    } catch (e) {
      // Rollback on failure: reload from DB
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove favorite'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        automaticallyImplyLeading: false,
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: _favoritesService.favoriteFilePathsNotifier,
        builder: (context, favoritePaths, _) {
          // Filter cached list based on current favorite paths
          final filteredFavorites = _cachedFavorites
              .where((song) => favoritePaths.contains(song['filePath']))
              .toList();

          if (filteredFavorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredFavorites.length,
            itemBuilder: (context, index) {
              final song = filteredFavorites[index];
              final String? playingPath = _audioService.currentFilePath.value;
              final bool isSelected =
                  playingPath != null && playingPath == song['filePath'];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10, right: 4),
                  onTap: () => _playSong(song),
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
                    onPressed: () => _removeFavorite(song['filePath']),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.grey[850],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
