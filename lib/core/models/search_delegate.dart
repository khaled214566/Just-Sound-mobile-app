import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:idgaf/core/configs/assets/app_vectors.dart';
import 'package:idgaf/core/models/files_loader.dart';

class MySearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () {
        if (query.isEmpty) {
          close(context, null);
        } else {
          query = '';
        }
      },
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SongLoader.loadSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No songs found'));
        }

        final allSongs = snapshot.data!;

        // Filter songs based on query
        final results = allSongs.where((song) {
          final title = (song['title'] as String).toLowerCase();
          final artist = (song['artist'] as String).toLowerCase();
          final album = (song['album'] as String).toLowerCase();
          final searchQuery = query.toLowerCase();

          return title.contains(searchQuery) ||
              artist.contains(searchQuery) ||
              album.contains(searchQuery);
        }).toList();

        if (results.isEmpty) {
          return Center(child: Text('No results found for "$query"'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final song = results[index];
            return ListTile(
              leading: song['artwork'] != null
                  ? Image.memory(
                      song['artwork'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : SvgPicture.asset(
                      AppVectors.songLogo,
                      width: 50,
                      height: 50,
                    ),
              title: Text(song['title']),
              subtitle: Text('${song['artist']} • ${song['album']}'),
              onTap: () {
                // Handle song selection
                close(context, song);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SongLoader.loadSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No songs found'));
        }

        final allSongs = snapshot.data!;

        // Filter songs based on query
        final suggestions = query.isEmpty
            ? allSongs
            : allSongs.where((song) {
                final title = (song['title'] as String).toLowerCase();
                final artist = (song['artist'] as String).toLowerCase();
                final searchQuery = query.toLowerCase();

                return title.contains(searchQuery) ||
                    artist.contains(searchQuery);
              }).toList();

        if (suggestions.isEmpty) {
          return Center(
            child: Text(
              query.isEmpty
                  ? 'Start typing to search'
                  : 'No songs match "$query"',
            ),
          );
        }

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final song = suggestions[index];
            return ListTile(
              leading: song['artwork'] != null
                  ? Image.memory(
                      song['artwork'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : SvgPicture.asset(
                      AppVectors.songLogo,
                      width: 50,
                      height: 50,
                    ),
              title: Text(song['title']),
              subtitle: Text('${song['artist']} • ${song['album']}'),
              onTap: () {
                // Handle song selection
              },
            );
          },
        );
      },
    );
  }
}
