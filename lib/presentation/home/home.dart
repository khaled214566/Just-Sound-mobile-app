import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:idgaf/core/configs/assets/app_vectors.dart';
import 'package:idgaf/core/models/audio_player.dart';
import 'package:idgaf/core/models/miniPlayer.dart';
import 'package:idgaf/presentation/pages/converter.dart';
import 'package:idgaf/presentation/pages/playlists.dart';
import 'package:idgaf/presentation/pages/songs_page.dart';
import 'package:idgaf/presentation/pages/favorites.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  // 👇 remove 'const' and use actual widgets
  final List<Widget> _pages = [
    const SongsPage(),
    const FavoritesPage(),
    const PlaylistsPage(),
    const DownloadPage(), // 👈 replaced placeholder
  ];

  @override
  void initState() {
    super.initState();
    _scaleControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _scaleAnimations = _scaleControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.3,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _scaleControllers[_selectedIndex].forward();
  }

  @override
  void dispose() {
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    _scaleControllers[_selectedIndex].reverse();
    _scaleControllers[index].forward();

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: AudioService().currentQueue,
            builder: (context, queue, _) {
              if (queue.isEmpty) return const SizedBox.shrink();
              return MiniPlayer(songs: queue);
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: const Color(0xff88D3EC),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        items: [
          BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: _scaleAnimations[0],
              child: SvgPicture.asset(AppVectors.songs, width: 24, height: 24),
            ),
            label: _selectedIndex == 0 ? 'Songs' : '',
          ),
          BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: _scaleAnimations[1],
              child: SvgPicture.asset(
                AppVectors.favorites,
                width: 24,
                height: 24,
              ),
            ),
            label: _selectedIndex == 1 ? 'Favorites' : '',
          ),
          BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: _scaleAnimations[2],
              child: SvgPicture.asset(
                AppVectors.playlists,
                width: 24,
                height: 24,
              ),
            ),
            label: _selectedIndex == 2 ? 'Playlists' : '',
          ),
          BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: _scaleAnimations[3],
              child: SvgPicture.asset(
                AppVectors.converter,
                width: 24,
                height: 24,
              ),
            ),
            label: _selectedIndex == 3 ? 'Converter' : '',
          ),
        ],
      ),
    );
  }
}
