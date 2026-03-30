import 'package:flutter/material.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  List<Map<String, dynamic>> songs = [
    {
      "title": "Rap God",
      "artist": "Eminem",
      "duration": "6:04",
      "isFavorite": false,
    },
    {
      "title": "Blinding Lights",
      "artist": "The Weeknd",
      "duration": "3:20",
      "isFavorite": true,
    },
  ];

  void toggleFavorite(int index) {
    setState(() {
      songs[index]["isFavorite"] = !songs[index]["isFavorite"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];

        return ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(song["title"]),
          subtitle: Text(song["artist"]),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(song["duration"]),
              IconButton(
                icon: Icon(
                  song["isFavorite"]
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                onPressed: () => toggleFavorite(index),
              ),
            ],
          ),
        );
      },
    );
  }
}