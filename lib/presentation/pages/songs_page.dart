import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:idgaf/core/configs/assets/app_vectors.dart';
import 'package:idgaf/core/models/search_delegate.dart';
import 'package:idgaf/core/models/audio_player.dart';
import 'package:idgaf/core/models/files_loader.dart';
import 'package:idgaf/core/models/permission.dart';
import 'package:idgaf/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:idgaf/core/models/BottomSheet.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final AudioService _audioService = AudioService();

  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;
  String _debugMessage = "Loading...";
  Set<int> _favorites = {}; // Track favorite song indices
  SortOption _currentSort = SortOption.title;
  SortBy _currentOrder = SortBy.ascending;

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
          _songs.sort((a, b) => compare(a['downloadDate'], b['downloadDate']));
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
