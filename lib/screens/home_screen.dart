// ============================================================
// home_screen.dart — polar-bear-themed landing screen.
//
// The scan button is the HERO. Everything else supports it.
//
// Layout (top → bottom):
//   1. Minimal header            — app name + profile icon
//   2. Nanuk the polar bear      — mascot with a speech bubble line
//   3. Big circular scan button  — pulsing, center-stage, hard to miss
//   4. Stat chips                — compact points / CO2 / streak
//   5. Footer row                — History + Eco tips
//
// Swap the mascot emoji for a PNG later by replacing _NanukMascot's
// child Text('🐻‍\u200d❄️') with Image.asset('assets/nanuk.png').
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // ---- Icy palette ----
  static const iceDeep = Color(0xFF173E6B);   // arctic night navy
  static const iceMid = Color(0xFF4A90B8);    // glacier blue
  static const iceSoft = Color(0xFFDCEEF7);   // pale sky
  static const iceWhite = Color(0xFFF6FAFD);  // almost-white snow
  static const accent = Color(0xFFFFB547);    // warm gold (points/awards)

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
      // Sky-to-snow gradient background.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HomeScreen.iceSoft, HomeScreen.iceWhite],
            stops: [0.0, 0.7],
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

                const SizedBox(height: 14),

                // ----- FOOTER ACTIONS -----
                Row(
                  children: [
                    Expanded(
                      child: _FooterButton(
                        icon: Icons.history_rounded,
                        label: 'History',
                        onTap: () => _showSnack('History coming soon'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FooterButton(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Eco tips',
                        onTap: () => _showSnack('Eco tips coming soon'),
                      ),
                    ),
                  ],
                ),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: HomeScreen.iceDeep,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.ac_unit_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'SustainScan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: HomeScreen.iceDeep,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded,
              color: HomeScreen.iceDeep),
          onPressed: () {},
          tooltip: 'Profile',
        ),
      ],
    );
  }
}

// ============================================================
// NANUK THE MASCOT — polar bear emoji + speech bubble.
// To upgrade to a PNG later:
//   Replace the Text('🐻\u200d❄️') with
//   Image.asset('assets/nanuk.png', width: 96, height: 96)
//   and add the asset to pubspec.yaml.
// ============================================================
class _NanukMascot extends StatelessWidget {
  const _NanukMascot();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bear in a frosty circle.
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: HomeScreen.iceSoft, width: 4),
            boxShadow: [
              BoxShadow(
                color: HomeScreen.iceMid.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          // Polar bear emoji (bear + ZWJ + snowflake).
          child: const Text('🐻\u200d❄️', style: TextStyle(fontSize: 54)),
        ),
        const SizedBox(width: 12),

        // Speech bubble.
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: HomeScreen.iceMid.withValues(alpha: 0.15),
                      blurRadius: 10,
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
                        color: HomeScreen.iceDeep,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scan a product to help save my home.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.black87,
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
                    color: Colors.white,
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
// SCAN HERO — big circular button with a pulsing ring.
// The main action of the whole app.
// ============================================================
class _ScanHero extends StatelessWidget {
  final AnimationController pulse;
  final VoidCallback onTap;
  const _ScanHero({required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated pulsing rings behind the button.
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

          // Foreground scan button.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [HomeScreen.iceMid, HomeScreen.iceDeep],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HomeScreen.iceDeep.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 72),
                    SizedBox(height: 10),
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
                        fontSize: 12,
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
        final opacity = (1.0 - t) * 0.35;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: HomeScreen.iceMid.withValues(alpha: opacity),
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
          iconColor: HomeScreen.accent,
          value: '0',
          label: 'Points',
        ),
        _Chip(
          icon: Icons.co2_rounded,
          iconColor: HomeScreen.iceMid,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: HomeScreen.iceMid.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: HomeScreen.iceDeep,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FOOTER BUTTON — light pill-style secondary action.
// ============================================================
class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeScreen.iceSoft, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: HomeScreen.iceDeep, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HomeScreen.iceDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
