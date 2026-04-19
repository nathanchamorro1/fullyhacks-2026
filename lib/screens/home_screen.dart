// ============================================================
// home_screen.dart — polar-bear-themed landing screen.
//
// Warm, character-driven aesthetic matching the results page:
// cream backdrop, gold accents, Nanuk front-and-center.
// The scan button keeps its glacier blue core so it still reads
// as "scan = tech action" — but it's wrapped in a warm gold halo.
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---- Warm palette (shared with results) ----
const _creamBG = Color(0xFFFFF8F0);
const _creamCard = Color(0xFFFFFDF9);
const _inkDark = Color(0xFF1A2B4A);
const _inkSoft = Color(0xFF4A5568);
const _sunGold = Color(0xFFFFB547);
const _sunGoldLight = Color(0xFFFFE082);
const _iceBlue = Color(0xFF4A90B8); // glacier blue (scan button only)
const _iceDeep = Color(0xFF173E6B); // arctic night navy
const _happyGreen = Color(0xFF66BB6A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Pulse animation for the scan button — draws the eye.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _onScanPressed() {
    // For now, scanner isn't wired yet — jump straight to the results
    // screen with demo data so we can design the flow. When the
    // barcode-scanner branch merges, swap this for '/scan'.
    Navigator.of(context).pushNamed('/results');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBG,
      bottomNavigationBar: _NanukNavBar(
        currentIndex: 0,
        onSnack: _showSnack,
      ),
      // Soft cream gradient with a warm golden glow in the corner.
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.9),
            radius: 1.1,
            colors: [
              Color(0xFFFFF2DE), // gentle sun-kissed cream at top
              _creamBG,          // base warm cream
            ],
            stops: [0.0, 0.85],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                const _TopBar(),
                const SizedBox(height: 12),

                // ----- MASCOT + SPEECH BUBBLE -----
                const _NanukMascot(),

                const SizedBox(height: 20),

                // ----- HERO SCAN BUTTON -----
                Expanded(
                  child: Center(
                    child: _ScanHero(
                      pulse: _pulse,
                      onTap: _onScanPressed,
                    ),
                  ),
                ),

                // ----- STAT CHIPS -----
                const _StatChipRow(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOP BAR — compact header with app name + profile icon.
// ============================================================
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Warm golden logo chip.
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_sunGoldLight, _sunGold],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _sunGold.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.ac_unit_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'Nanuk',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _inkDark,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '· sustainable scan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _inkSoft.withValues(alpha: 0.75),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// NANUK THE MASCOT — polar bear emoji + warm speech bubble.
// ============================================================
class _NanukMascot extends StatelessWidget {
  const _NanukMascot();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bear in a warm cream circle with a gold ring.
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _creamCard,
            border: Border.all(color: _sunGold.withValues(alpha: 0.45), width: 3),
            boxShadow: [
              BoxShadow(
                color: _sunGold.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          // Polar bear emoji (bear + ZWJ + snowflake).
          child: const Text('🐻\u200d❄️', style: TextStyle(fontSize: 54)),
        ),
        const SizedBox(width: 12),

        // Speech bubble — matches _NanukQuote style from results.
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _creamCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _sunGold.withValues(alpha: 0.30), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _sunGold.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, I'm Nanuk!",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _inkDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scan a product to help save my home 🌍',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: _inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Little tail of the bubble pointing at the bear.
              Positioned(
                left: -6,
                top: 22,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _creamCard,
                      border: Border(
                        bottom: BorderSide(
                          color: _sunGold.withValues(alpha: 0.30),
                          width: 1.5,
                        ),
                        left: BorderSide(
                          color: _sunGold.withValues(alpha: 0.30),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SCAN HERO — warm gold halo wrapping a glacier-blue button.
// ============================================================
class _ScanHero extends StatelessWidget {
  final AnimationController pulse;
  final VoidCallback onTap;
  const _ScanHero({required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Warm golden pulsing rings behind the button.
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  _pulseRing(offset: 0.0),
                  _pulseRing(offset: 0.5),
                ],
              );
            },
          ),

          // Static soft golden halo behind the button.
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _sunGold.withValues(alpha: 0.22),
                  _sunGold.withValues(alpha: 0.0),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),

          // Foreground scan button — still glacier-blue so "scan" reads.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_iceBlue, _iceDeep],
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: _iceDeep.withValues(alpha: 0.40),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: _sunGold.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 68),
                    SizedBox(height: 8),
                    Text(
                      'SCAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'tap to start',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // One pulse ring. `offset` staggers multiple rings so they cascade.
  Widget _pulseRing({required double offset}) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final t = (pulse.value + offset) % 1.0;
        final size = 210 + (t * 70);
        final opacity = (1.0 - t) * 0.45;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _sunGold.withValues(alpha: opacity),
              width: 4,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// STAT CHIPS — compact row showing points / CO2 / streak.
// ============================================================
class _StatChipRow extends StatelessWidget {
  const _StatChipRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _Chip(
          icon: Icons.emoji_events_rounded,
          iconColor: _sunGold,
          value: '0',
          label: 'Points',
        ),
        _Chip(
          icon: Icons.co2_rounded,
          iconColor: _happyGreen,
          value: '0 kg',
          label: 'CO\u2082 saved',
        ),
        _Chip(
          icon: Icons.local_fire_department_rounded,
          iconColor: Color(0xFFFF7043),
          value: '0',
          label: 'Day streak',
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _Chip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _creamCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _sunGold.withValues(alpha: 0.20), width: 1),
        boxShadow: [
          BoxShadow(
            color: _sunGold.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _inkDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10.5, color: _inkSoft, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOTTOM NAV BAR — warm cream bar with 4 tabs.
// Active tab gets a golden pill behind the icon.
// Currently only Home is functional; the rest show a snackbar.
// ============================================================
class _NanukNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(String) onSnack;

  const _NanukNavBar({
    required this.currentIndex,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _creamCard,
        border: Border(
          top: BorderSide(
            color: _sunGold.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _inkDark.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () {}, // already on home
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                active: currentIndex == 1,
                onTap: () => onSnack('History coming soon'),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Awards',
                active: currentIndex == 2,
                onTap: () => onSnack('Awards coming soon'),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                active: currentIndex == 3,
                onTap: () => onSnack('Profile coming soon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _sunGold : _inkSoft;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Golden pill behind the icon when active.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? _sunGold.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight:
                        active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
