// ============================================================
// home_screen.dart  —  the landing screen of the app.
//
// Beginner cheatsheet for the widgets you'll see below:
//
//   Scaffold  — the standard "app screen" skeleton. Gives you an AppBar,
//               a body area, bottom nav, etc. for free.
//   SafeArea  — pads content so it doesn't sit under the phone's notch
//               or the iOS home indicator.
//   Padding   — adds space around a child widget.
//   Column    — stacks children vertically.
//   Row       — stacks children horizontally.
//   Expanded  — inside a Row/Column, makes a child take leftover space.
//   SizedBox  — an empty box used as a spacer (height: 12 is a 12px gap).
//   Spacer    — flexible spacer that pushes siblings apart.
//   Text      — draws text with a style.
//   Card      — a rounded container with a subtle background color.
//   FilledButton / OutlinedButton — Material 3 buttons.
//
// The whole screen is built by returning a tree of these from build().
// Flutter re-runs build() whenever it needs to repaint.
//
// This widget is STATELESS (doesn't change over time). Later, when we
// want to show real points that update, we'll convert to StatefulWidget.
// ============================================================

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // grab colors + text styles from MaterialApp

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // L, T, R, B
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // make kids full width
            children: [
              // ---- App title + tagline ----
              Text(
                'SustainScan',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan it. Know its impact. Shop better.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              // ---- Stat cards (placeholders for now) ----
              // Later we'll read real numbers from shared_preferences.
              const Row(
                children: [
                  Expanded(child: _StatCard(label: 'Points', value: '0')),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(label: 'Carbon this week', value: '— kg'),
                  ),
                ],
              ),

              // Spacer pushes the button to the bottom of the screen.
              const Spacer(),

              // ---- Primary action: Scan ----
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // When tapped, this function runs.
                onPressed: () => _onScanPressed(context),
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: const Text('Scan a product'),
              ),

              const SizedBox(height: 12),

              // ---- Secondary action: History (stub) ----
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History coming soon')),
                  );
                },
                child: const Text('View history'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Scan button handler.
  //
  // RIGHT NOW: shows a SnackBar (little toast at the bottom).
  // This is a placeholder because the real scanner lives on the
  // `barcode-scanner` branch. Once that branch merges into main,
  // come back here and replace the body of this function with:
  //
  //     Navigator.of(context).pushNamed('/scan');
  //
  // (and in main.dart, register the /scan route).
  // ----------------------------------------------------------
  void _onScanPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanner hooks up once the barcode-scanner branch merges'),
      ),
    );
  }
}

// Private helper widget (the leading underscore makes it file-private).
// Separating small UI chunks into their own widgets keeps build() readable.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
