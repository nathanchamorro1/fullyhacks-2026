// ============================================================
// main.dart  —  the entry point of every Flutter app.
//
// Quick mental model:
//   - A Flutter app is a tree of "widgets". Everything is a widget:
//     buttons, text, the whole screen, the app itself.
//   - main() runs runApp() on the root widget.
//   - MaterialApp wires up theming, navigation, etc.
//   - `home:` tells MaterialApp which widget to show first.
// ============================================================

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const SustainScanApp());
}

class SustainScanApp extends StatelessWidget {
  const SustainScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SustainScan',
      debugShowCheckedModeBanner: false, // hides the red "DEBUG" ribbon
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D57), // forest green vibe
          brightness: Brightness.light,
        ),
      ),
      // First screen the user sees.
      home: const HomeScreen(),
    );
  }
}
