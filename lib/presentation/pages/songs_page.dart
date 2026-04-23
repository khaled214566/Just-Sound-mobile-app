import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:idgaf/core/configs/assets/app_vectors.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
import 'package:idgaf/core/models/playlist_service.dart';
import 'package:idgaf/core/models/search_delegate.dart';
import 'package:idgaf/core/models/audio_player.dart';
import 'package:idgaf/core/models/files_loader.dart';
import 'package:idgaf/core/models/permission.dart';
import 'package:idgaf/core/models/favorites_service.dart';
import 'package:idgaf/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:idgaf/core/models/BottomSheet.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final AudioService _audioService = AudioService();
  final FavoritesService _favoritesService = FavoritesService();

  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;
  String _debugMessage = 'Loading...';

  SortOption _currentSort = SortOption.date;
  SortBy _currentOrder = SortBy.descending;

  // Multi‑selection state
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _initialize();

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

  Future<void> _showAddToPlaylistSheet(
    BuildContext context,
    List<String> songFilePaths,
  ) async {
    final service = await PlaylistService.instance;
    final playlists = service.playlistsNotifier.value;

    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playlists yet. Create one first.')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: playlists.length,
        itemBuilder: (_, i) {
          final playlist = playlists[i];
          return ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(playlist.name),
            onTap: () async {
              // Add each selected song to the playlist
              for (final path in songFilePaths) {
                await service.addSongToPlaylist(playlist.id, path);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Added ${songFilePaths.length} song(s) to “${playlist.name}”',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _initialize() async {
    final granted = await PermissionService.requestStoragePermissions();

    if (!granted) {
      setState(() {
        _debugMessage = 'Storage permission denied';
        _isLoading = false;
      });
      return;
    }

    final songs = await SongLoader.loadSongs();

    setState(() {
      _songs = songs;
      _isLoading = false;
      _debugMessage = songs.isEmpty
          ? 'No MP3 files found'
          : 'Loaded ${songs.length} songs';
    });

    _audioService.setQueue(_songs);
    _sortSongs(_currentSort, _currentOrder);
  }

  void _sortSongs(SortOption option, SortBy order) {
    setState(() {
      int compare<T extends Comparable>(T a, T b) =>
          order == SortBy.ascending ? a.compareTo(b) : b.compareTo(a);

      switch (option) {
        case SortOption.title:
          _songs.sort(
            (a, b) =>
                compare(a['title'].toLowerCase(), b['title'].toLowerCase()),
          );
          break;
        case SortOption.artist:
          _songs.sort(
            (a, b) =>
                compare(a['artist'].toLowerCase(), b['artist'].toLowerCase()),
          );
          break;
        case SortOption.album:
          _songs.sort(
            (a, b) =>
                compare(a['album'].toLowerCase(), b['album'].toLowerCase()),
          );
          break;
        case SortOption.date:
          _songs.sort(
            (a, b) => compare(
              a['downloadDate'] as DateTime,
              b['downloadDate'] as DateTime,
            ),
          );
          break;
      }

      _audioService.setQueue(_songs);
    });
  }

  Future<void> _playSong(int index) async {
    if (_isSelectionMode) return;
    await _audioService.playFromList(_songs, index);
  }

  Future<void> _toggleFavorite(
    String filePath,
    Map<String, dynamic> song,
  ) async {
    if (_isSelectionMode) return; // Disable during selection
    if (_favoritesService.isFavorite(filePath)) {
      await _favoritesService.removeFavorite(filePath);
    } else {
      await _favoritesService.addFavorite(song);
    }
  }

  void _enterSelectionMode(int startIndex) {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.clear();
      _selectedIndices.add(startIndex);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _addSelectedToPlaylist() async {
    if (_selectedIndices.isEmpty) return;
    final selectedPaths = _selectedIndices
        .map((idx) => _songs[idx]['filePath'] as String)
        .toList();
    await _showAddToPlaylistSheet(context, selectedPaths);
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Just Sound'),
          backgroundColor: AppColors.darkGrey,
          automaticallyImplyLeading: false,
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
          title: const Text('Just Sound'),
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
        ),
        body: Center(child: Text(_debugMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Just Sound'),
        backgroundColor: AppColors.darkGrey,
        automaticallyImplyLeading: false,
        actions: _buildAppBarActions(),
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: _favoritesService.favoriteFilePathsNotifier,
        builder: (context, favoritePaths, _) {
          return ListView.builder(
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              final song = _songs[index];
              final String? playingPath = _audioService.currentFilePath.value;
              final bool isPlaying =
                  playingPath != null && playingPath == song['filePath'];
              final bool isFavorite = favoritePaths.contains(song['filePath']);
              final bool isSelected = _selectedIndices.contains(index);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10, right: 4),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(index);
                    } else {
                      _playSong(index);
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _enterSelectionMode(index);
                    }
                  },
                  shape: isPlaying && !_isSelectionMode
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
                      : (context.watch<ThemeCubit>().state == ThemeMode.light)
                      ? SvgPicture.asset(
                          AppVectors.songLogo_light,
                          width: 50,
                          height: 50,
                        )
                      : SvgPicture.asset(
                          AppVectors.songLogo_dark,
                          width: 50,
                          height: 50,
                        ),
                  title: Text(
                    song['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPlaying && !_isSelectionMode
                          ? AppColors.lightBlue
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "${song['artist']} • ${song['album']}",
                    style: TextStyle(
                      color: isPlaying && !_isSelectionMode
                          ? AppColors.lightBlue
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: null, // toggled by tile tap
                          activeColor: AppColors.lightBlue,
                        )
                      : IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                          ),
                          onPressed: () =>
                              _toggleFavorite(song['filePath'], song),
                        ),
                  selected: isPlaying && !_isSelectionMode,
                  selectedTileColor: AppColors.primary,
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        if (_selectedIndices.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: _addSelectedToPlaylist,
            tooltip: 'Add to playlist',
          ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
          tooltip: 'Cancel',
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                    _debugMessage = 'Scanning...';
                  });
                  await _initialize();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Scanned ${_songs.length} songs'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            showSearch(context: context, delegate: MySearchDelegate());
          },
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () async {
            final result = await showSortFilterSheet(
              context,
              initialSort: _currentSort,
              initialWay: _currentOrder,
            );
            if (result != null) {
              setState(() {
                _currentSort = result.sortBy;
                _currentOrder = result.genre;
              });
              _sortSongs(_currentSort, _currentOrder);
            }
          },
        ),
      ];
    }
  }
}
