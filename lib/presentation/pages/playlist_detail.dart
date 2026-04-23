// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
import 'package:idgaf/core/models/audio_player.dart';
import 'package:idgaf/core/models/playlist.dart';
import 'package:idgaf/core/models/playlist_service.dart';
import 'package:idgaf/core/models/files_loader.dart';
import 'package:idgaf/core/models/miniPlayer.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;
  final PlaylistService playlistService;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
    required this.playlistService,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final AudioService _audioService = AudioService();
  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;

  // Multi‑selection state
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final List<Map<String, dynamic>> loaded = [];
    for (final filePath in widget.playlist.songIds) {
      try {
        final metadata = await getSongMetadata(filePath);
        loaded.add(metadata);
      } catch (e) {
        debugPrint('Failed to load $filePath: $e');
      }
    }
    if (mounted) {
      setState(() {
        _songs = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _playSong(int index) async {
    if (_isSelectionMode) return; // never play when selecting
    await _audioService.playFromList(_songs, index);
  }

  Future<void> _removeSong(String filePath) async {
    await widget.playlistService.removeSongFromPlaylist(
      widget.playlist.id,
      filePath,
    );
    setState(() {
      _songs.removeWhere((s) => s['filePath'] == filePath);
    });
  }

  /// Remove all selected songs from the playlist (not from device).
  Future<void> _deleteSelected() async {
    final filePathsToRemove = _selectedIndices
        .map((idx) => _songs[idx]['filePath'] as String)
        .toList();

    // Batch remove from playlist service
    for (final path in filePathsToRemove) {
      await widget.playlistService.removeSongFromPlaylist(
        widget.playlist.id,
        path,
      );
    }

    // Update local list
    setState(() {
      _songs.removeWhere(
        (song) => filePathsToRemove.contains(song['filePath'] as String),
      );
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkGrey,
        title: Text(widget.playlist.name),
        actions: _buildAppBarActions(),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_note, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No songs in this playlist',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Long‑press a song in the Songs tab to add it',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ValueListenableBuilder<String?>(
                    valueListenable: _audioService.currentFilePath,
                    builder: (context, playingPath, _) {
                      return ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          final bool isSelected = _selectedIndices.contains(
                            index,
                          );
                          final bool isPlaying =
                              playingPath == song['filePath'];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
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
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white54,
                                    ),
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
                              song['artist'],
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
                                    onChanged:
                                        null, // visual only – toggled by tile tap
                                    activeColor: AppColors.lightBlue,
                                  )
                                : null,
                            selected: isPlaying && !_isSelectionMode,
                            selectedTileColor: AppColors.primary,
                          );
                        },
                      );
                    },
                  ),
          ),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _audioService.currentQueue,
            builder: (context, queue, _) {
              if (queue.isEmpty) return const SizedBox.shrink();
              return MiniPlayer(songs: queue);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        if (_selectedIndices.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSelected,
            tooltip: 'Remove selected',
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
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final controller = TextEditingController(
              text: widget.playlist.name,
            );
            final newName = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Rename Playlist'),
                content: TextField(controller: controller, autofocus: true),
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
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
            if (newName != null) {
              await widget.playlistService.renamePlaylist(
                widget.playlist.id,
                newName,
              );
              setState(() {}); // refresh title
            }
          },
        ),
      ];
    }
  }
}
