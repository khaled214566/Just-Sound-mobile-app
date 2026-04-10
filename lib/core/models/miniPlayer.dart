import 'package:flutter/material.dart';
import 'package:idgaf/core/models/audio_player.dart';

class MiniPlayer extends StatelessWidget {
  final List<Map<String, dynamic>> songs;

  const MiniPlayer({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    // 🔥 Listen to currentIndex: when the song changes, this builder rebuilds
    return ValueListenableBuilder<int>(
      valueListenable: audioService.currentIndex,
      builder: (context, index, child) {
        // If no song is selected (-1), hide the player
        if (index == -1 || index >= songs.length)
          return const SizedBox.shrink();

        final currentSong = songs[index];

        return Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // --- Song Info ---
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSong['title'] ?? 'Unknown Title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentSong['artist'] ?? 'Unknown Artist',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // --- Previous Button ---
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () => audioService.playPrevious(),
              ),

              // --- Play/Pause Button ---
              // 🔥 Listen to isPlaying separately so only this button glows/changes
              ValueListenableBuilder<bool>(
                valueListenable: audioService.isPlaying,
                builder: (context, playing, _) {
                  return IconButton(
                    icon: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      playing ? audioService.pause() : audioService.resume();
                    },
                  );
                },
              ),

              // --- Next Button ---
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () => audioService.playNext(),
              ),
            ],
          ),
        );
      },
    );
  }
}
