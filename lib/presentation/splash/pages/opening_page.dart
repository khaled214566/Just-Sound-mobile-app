import 'package:flutter/material.dart';
import 'package:idgaf/presentation/intro/pages/get_started.dart';
import 'package:idgaf/presentation/home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
// your main app page

class OpeningPage extends StatefulWidget {
  const OpeningPage({super.key});

  @override
  State<OpeningPage> createState() => _OpeningPageState();
}

class _OpeningPageState extends State<OpeningPage> {
  @override
  void initState() {
    super.initState();
    checkFirstLaunch();
  }

  Future<void> checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);

      // First time → show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedPage()),
      );
    } else {
      // Not first time → skip
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
