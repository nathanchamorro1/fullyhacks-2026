import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/awards_screen.dart';
import 'screens/results_screen.dart';
import 'screens/scan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const NanukApp());
}

class NanukApp extends StatelessWidget {
  const NanukApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nanuk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: kBg,
        splashColor: kBlue.withOpacity(0.10),
        highlightColor: kBlue.withOpacity(0.06),
        fontFamily: 'sans-serif',
      ),
      home: const AppShell(),
      routes: {
        '/scan':    (_) => const ScanScreen(),
        '/results': (ctx) => ResultsScreen(
              result: ModalRoute.of(ctx)!.settings.arguments as dynamic,
            ),
      },
    );
  }
}

// ============================================================
// APP SHELL
// ============================================================
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0; // 0=Home, 1=History, 2=Awards

  static const _screens = [
    HomeScreen(),
    HistoryScreen(),
    AwardsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _NanukBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Bottom nav bar — 3 evenly spaced tabs ────────────────────────────────
class _NanukBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _NanukBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(
          top: BorderSide(color: kInk.withOpacity(0.08), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavBtn(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'HOME',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavBtn(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'HISTORY',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavBtn(
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events_rounded,
                label: 'AWARDS',
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? kBlue : kInkLight;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 4 : 0,
                height: active ? 4 : 0,
                decoration: const BoxDecoration(
                  color: kBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
