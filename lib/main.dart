// ============================================================
// main.dart  —  app entry point.
//
// Registers named routes so any screen can navigate to another by
// calling Navigator.pushNamed(context, '/results').
// ============================================================

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/results_screen.dart';

void main() {
  runApp(const SustainScanApp());
}

class SustainScanApp extends StatelessWidget {
  const SustainScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nanuk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90B8), // glacier blue
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/results': (_) => ResultsScreen(), // uses demo data until wired
      },
    );
  }
}
