import 'package:flutter/material.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
import 'package:idgaf/core/models/BottomSheet.dart';
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

  List<Map<String, dynamic>> _cachedFavorites = [];
  bool _isLoading = true;

  SortOption _currentSort = SortOption.date;
  SortBy _currentOrder = SortBy.descending;

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    _audioService.currentFilePath.addListener(_onAudioStateChanged);
    _audioService.isPlaying.addListener(_onAudioStateChanged);
    _favoritesService.favoriteFilePathsNotifier.addListener(
      _onFavoritesChanged,
    );
  }

  @override
  void dispose() {
    _audioService.currentFilePath.removeListener(_onAudioStateChanged);
    _audioService.isPlaying.removeListener(_onAudioStateChanged);
    _favoritesService.favoriteFilePathsNotifier.removeListener(
      _onFavoritesChanged,
    );
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  void _onFavoritesChanged() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getAllFavorites();
    if (mounted) {
      setState(() {
        // Create a mutable copy – the DB returns a read-only list
        _cachedFavorites = List.from(favorites);
        _isLoading = false;
        _applySort(); // Re-apply user's sort preference
      });
    }
  }

  // Applies the current sort to _cachedFavorites (no setState here)
  void _applySort() {
    if (_cachedFavorites.isEmpty) return;

    int compare<T extends Comparable>(T a, T b) =>
        _currentOrder == SortBy.ascending ? a.compareTo(b) : b.compareTo(a);

    switch (_currentSort) {
      case SortOption.title:
        _cachedFavorites.sort(
          (a, b) => compare(a['title'].toLowerCase(), b['title'].toLowerCase()),
        );
        break;
      case SortOption.artist:
        _cachedFavorites.sort(
          (a, b) =>
              compare(a['artist'].toLowerCase(), b['artist'].toLowerCase()),
        );
        break;
      case SortOption.album:
        _cachedFavorites.sort(
          (a, b) => compare(a['album'].toLowerCase(), b['album'].toLowerCase()),
        );
        break;
      case SortOption.date:
        _cachedFavorites.sort(
          (a, b) => compare(a['downloadDate'] as int, b['downloadDate'] as int),
        );
        break;
    }
  }

  // Called when the user selects a new sort option
  void _sortFavorites(SortOption option, SortBy order) {
    setState(() {
      _currentSort = option;
      _currentOrder = order;
      _applySort();
    });
  }

  Future<void> _playSong(Map<String, dynamic> song) async {
    final index = _cachedFavorites.indexWhere(
      (s) => s['filePath'] == song['filePath'],
    );
    if (index != -1) {
      await _audioService.playFromList(_cachedFavorites, index);
    }
  }

  Future<void> _removeFavorite(String filePath) async {
    try {
      await _favoritesService.removeFavorite(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
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
          backgroundColor: AppColors.darkGrey,
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        backgroundColor: AppColors.darkGrey,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () async {
              final result = await showSortFilterSheet(
                context,
                initialSort: _currentSort,
                initialWay: _currentOrder,
              );
              if (result != null) {
                _sortFavorites(result.sortBy, result.genre);
              }
            },
          ),
        ],
      ),
      body: _cachedFavorites.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              itemCount: _cachedFavorites.length,
              itemBuilder: (context, index) {
                final song = _cachedFavorites[index];
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
                        color: isSelected ? AppColors.lightBlue : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song['artist'],
                      style: TextStyle(
                        color: isSelected ? AppColors.lightBlue : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _removeFavorite(song['filePath']),
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.primary,
                  ),
                );
              },
            ),
    );
  }
}
