// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:idgaf/core/configs/assets/app_vectors.dart';
import 'package:idgaf/presentation/pages/songs_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;
  final List<Widget> _pages = const [
    SongsPage(),
    Center(child: Text('Favorites Page')),
    Center(child: Text('Playlists Page')),
    Center(child: Text('Converter Page')),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers for each navigation item
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

    // Play animation for initially selected item
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
    // Reverse the previous selection
    _scaleControllers[_selectedIndex].reverse();

    // Forward the new selection
    _scaleControllers[index].forward();

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: const Color(0xff88D3EC),
        selectedLabelStyle: const TextStyle(
          // Color when selected
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

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Songs';
      case 1:
        return 'Favorites';
      case 2:
        return 'Playlists';
      case 3:
        return 'Converter';
      default:
        return 'Home';
    }
  }
}
