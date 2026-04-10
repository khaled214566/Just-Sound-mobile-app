import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:idgaf/core/configs/assets/app_vectors.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
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

  SortOption _currentSort = SortOption.title;
  SortBy _currentOrder = SortBy.ascending;

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

    // Update the audio service queue
    _audioService.setQueue(_songs);
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
    await _audioService.playFromList(_songs, index);
  }

  Future<void> _toggleFavorite(
    String filePath,
    Map<String, dynamic> song,
  ) async {
    if (_favoritesService.isFavorite(filePath)) {
      await _favoritesService.removeFavorite(filePath);
    } else {
      await _favoritesService.addFavorite(song);
    }
    // No setState needed — the ValueListenableBuilder will handle it
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Just Sound'),
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
          automaticallyImplyLeading: false,
        ),
        body: Center(child: Text(_debugMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Just Sound'),
        automaticallyImplyLeading: false,
        actions: [
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
        ],
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: _favoritesService.favoriteFilePathsNotifier,
        builder: (context, favoritePaths, _) {
          return ListView.builder(
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              final song = _songs[index];
              final String? playingPath = _audioService.currentFilePath.value;
              final bool isSelected =
                  playingPath != null && playingPath == song['filePath'];
              final bool isFavorite = favoritePaths.contains(song['filePath']);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10, right: 4),
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
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () => _toggleFavorite(song['filePath'], song),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
