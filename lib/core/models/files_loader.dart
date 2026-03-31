import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;
  late AudioPlayer _audioPlayer;
  int? _currentPlayingIndex;
  String _debugMessage = "Initializing...";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _requestPermissionsAndLoadSongs();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndLoadSongs() async {
    try {
      // Request permissions
      final storageStatus = await Permission.storage.request();
      final manageStorageStatus = await Permission.manageExternalStorage.request();

      debugPrint("Storage permission: $storageStatus");
      debugPrint("Manage external storage: $manageStorageStatus");

      setState(() {
        _debugMessage = "Permission status: Storage=$storageStatus, Manage=$manageStorageStatus";
      });

      await _loadSongs();
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
      setState(() {
        _debugMessage = "Permission error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSongs() async {
    try {
      List<Map<String, dynamic>> songsList = [];

      // List of directories to search
      final dirsToSearch = [
        "/storage/emulated/0/Music",
        "/storage/emulated/0/Download",
        "/sdcard/Music",
        "/sdcard/Download",
      ];

      debugPrint("Starting to search for songs...");
      setState(() {
        _debugMessage = "Searching in ${dirsToSearch.length} directories...";
      });

      for (final dirPath in dirsToSearch) {
        final dir = Directory(dirPath);

        debugPrint("Checking: $dirPath - Exists: ${dir.existsSync()}");

        if (dir.existsSync()) {
          try {
            final allItems = dir.listSync(recursive: false);
            debugPrint("  Items found in $dirPath: ${allItems.length}");

            for (var item in allItems) {
              debugPrint("    - ${item.path} (${item is File ? 'FILE' : 'DIR'})");
            }

            final files = allItems
                .whereType<File>()
                .where((file) => file.path.toLowerCase().endsWith('.mp3'))
                .toList();

            debugPrint("  MP3 files in $dirPath: ${files.length}");

            for (var file in files) {
              final fileName = file.path.split('/').last;
              final titleWithoutExtension = fileName.replaceAll('.mp3', '');

              debugPrint("  Adding song: $titleWithoutExtension");

              songsList.add({
                'filePath': file.path,
                'fileName': fileName,
                'title': titleWithoutExtension,
                'artist': 'Unknown Artist',
                'album': 'Unknown Album',
                'duration': 0,
              });
            }
          } catch (e) {
            debugPrint("Error scanning $dirPath: $e");
          }
        } else {
          debugPrint("Directory not found: $dirPath");
        }
      }

      debugPrint("Total songs found: ${songsList.length}");

      setState(() {
        _songs = songsList;
        _isLoading = false;
        if (_songs.isEmpty) {
          _debugMessage = "No MP3 files found. Make sure to add songs to /sdcard/Music/ or /sdcard/Download/";
        } else {
          _debugMessage = "Loaded ${_songs.length} songs";
        }
      });
    } catch (e) {
      debugPrint("Error loading songs: $e");
      setState(() {
        _debugMessage = "Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _playSong(int index) async {
    try {
      final song = _songs[index];
      final filePath = song['filePath'];

      debugPrint("Attempting to play: $filePath");

      if (_currentPlayingIndex != null && _currentPlayingIndex != index) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();

      setState(() {
        _currentPlayingIndex = index;
      });

      debugPrint("Now playing: ${song['title']}");
    } catch (e) {
      debugPrint("Error playing song: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing song: $e")),
      );
    }
  }

  Future<void> _pauseSong() async {
    await _audioPlayer.pause();
  }

  Future<void> _resumeSong() async {
    await _audioPlayer.play();
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _debugMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Songs")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("No songs found"),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _debugMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _debugMessage = "Rescanning...";
                  });
                  _loadSongs();
                },
                child: const Text("Try Again"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Songs"),
            Text(
              "${_songs.length} songs",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          final isPlaying = _currentPlayingIndex == index;

          return ListTile(
            leading: Icon(
              isPlaying ? Icons.music_note : Icons.music_note_outlined,
              color: isPlaying ? Colors.blue : null,
            ),
            title: Text(
              song['title'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                color: isPlaying ? Colors.blue : null,
              ),
            ),
            subtitle: Text(song['artist']),
            trailing: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isPlaying ? Colors.blue : null,
              ),
              onPressed: () {
                if (isPlaying) {
                  _pauseSong();
                } else if (_currentPlayingIndex == index) {
                  _resumeSong();
                } else {
                  _playSong(index);
                }
              },
            ),
            onTap: () {
              if (!isPlaying) {
                _playSong(index);
              }
            },
          );
        },
      ),
    );
  }
}