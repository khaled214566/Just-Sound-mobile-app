import 'dart:io';
import 'package:flutter/material.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  List<FileSystemEntity> _songs = [];

  final String folderPath = r"C:\Users\khaled\OneDrive\Music\ytyb"; // Hardcoded folder

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() {
    final dir = Directory(folderPath);

    if (dir.existsSync()) {
      final files = dir.listSync().where((file) => file.path.endsWith('.mp3')).toList();
      setState(() {
        _songs = files;
      });
    } else {
      debugPrint("Folder does not exist: $folderPath");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Songs")),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final file = _songs[index];
          final fileName = file.path.split('\\').last;
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(fileName),
            subtitle: Text("Artist Unknown"), // You can extract metadata later
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                // Play the song later with just_audio
              },
            ),
          );
        },
      ),
    );
  }
}