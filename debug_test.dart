import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const DebugApp());
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Debug Test - Logo Loading', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              // Try loading the SVG
              SvgPicture.asset(
                'assets/vectors/app_logo.svg',
                width: 100,
                height: 100,
                placeholderBuilder: (context) => const CircularProgressIndicator(),
              ),
              const SizedBox(height: 20),
              // Fallback text if SVG fails
              const Text('If you see this text but no logo, SVG loading failed'),
            ],
          ),
        ),
      ),
    );
  }
}
