// ============================================================
// home_screen.dart — light background, solid scan box hero.
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/stats_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _stats = StatsService();
  UserStats _userStats = UserStats.empty;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _stats.load();
    if (mounted) setState(() => _userStats = s);
  }

  // Reload stats every time we return from the scan screen
  Future<void> _onScanTap() async {
    await Navigator.of(context).pushNamed('/scan');
    _loadStats(); // refresh after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              _TopBar(),
              const SizedBox(height: 16),
              const _MascotRow(),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: _ScanHero(onTap: _onScanTap),
                ),
              ),
              const SizedBox(height: 24),
              _StatRow(
                scans:     _userStats.scanCount,
                streak:    _userStats.streakDays,
                avgGrade:  _userStats.avgGrade,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  await StatsService().recordScan(85);
                  await Navigator.of(context).pushNamed('/results');
                  _loadStats();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Preview result →',
                    style: kLabelStyle(size: 10, color: kBlue, letterSpacing: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  _TopBar();

  String get _dateLabel {
    final n = DateTime.now();
    const days   = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
    const months = ['JAN','FEB','MAR','APR','MAY','JUN',
                    'JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${days[n.weekday - 1]} · ${months[n.month - 1]} ${n.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: kInk,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐻‍❄️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('NANUK',
                  style: kLabelStyle(size: 12, color: Colors.white, letterSpacing: 2.0)),
            ],
          ),
        ),
        const Spacer(),
        Text(_dateLabel, style: kLabelStyle(size: 10, color: kInkMuted)),
      ],
    );
  }
}

// ============================================================
// MASCOT ROW
// ============================================================
class _MascotRow extends StatelessWidget {
  const _MascotRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: kBlueSoft,
            shape: BoxShape.circle,
            border: Border.all(color: kBlue.withOpacity(0.30), width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Text('🐻‍❄️', style: TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kInk.withOpacity(0.08), width: 1),
                ),
                child: Text(
                  '"Scan a product to see how it affects my Arctic home!"',
                  style: kBodyStyle(size: 12, color: kInk, weight: FontWeight.w500),
                ),
              ),
              Positioned(
                left: -5,
                top: 14,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: kSurface,
                      border: Border(
                        bottom: BorderSide(color: kInk.withOpacity(0.08), width: 1),
                        left:   BorderSide(color: kInk.withOpacity(0.08), width: 1),
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
// SCAN HERO — solid dark box with static corner brackets.
// No animation, no glow. Clean and minimal.
// ============================================================
class _ScanHero extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Static corner brackets
            ..._corners(),
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 68,
                ),
                const SizedBox(height: 16),
                Text(
                  'SCAN',
                  style: kDisplayStyle(
                    size: 26,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'tap to start',
                  style: kBodyStyle(size: 12, color: Colors.white38),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners() {
    const inset = 20.0;
    return [
      Positioned(top: inset,    left: inset,  child: const _Bracket(top: true,  left: true)),
      Positioned(top: inset,    right: inset, child: const _Bracket(top: true,  left: false)),
      Positioned(bottom: inset, left: inset,  child: const _Bracket(top: false, left: true)),
      Positioned(bottom: inset, right: inset, child: const _Bracket(top: false, left: false)),
    ];
  }
}

// ── Static L-shaped corner bracket ───────────────────────────
class _Bracket extends StatelessWidget {
  final bool top;
  final bool left;
  const _Bracket({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: CustomPaint(painter: _BracketPainter(top: top, left: left)),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool top;
  final bool left;
  const _BracketPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kBlue
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    if (left && top) {
      canvas.drawLine(Offset(0, h), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
    } else if (!left && top) {
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (left && !top) {
      canvas.drawLine(const Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter old) => false;
}

// ============================================================
// STAT ROW
// ============================================================
class _StatRow extends StatelessWidget {
  final int scans;
  final int streak;
  final String avgGrade;
  const _StatRow({
    required this.scans,
    required this.streak,
    required this.avgGrade,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'SCANS',     value: '$scans',   icon: Icons.qr_code_rounded,               accent: kBlue),
        const SizedBox(width: 10),
        streak > 0
            ? _StreakChip(days: streak)
            : _StatChip(label: 'STREAK', value: '0',     icon: Icons.local_fire_department_rounded,  accent: kInkMuted),
        const SizedBox(width: 10),
        _StatChip(label: 'AVG GRADE', value: avgGrade,   icon: Icons.grade_rounded,                 accent: kMoss, mono: true),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool mono;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kInk.withOpacity(0.07)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: mono
                  ? kMonoStyle(size: 20, color: kInk)
                  : kDisplayStyle(size: 22, color: kInk),
            ),
            const SizedBox(height: 3),
            Text(label, style: kLabelStyle(size: 9, color: kInkMuted)),
          ],
        ),
      ),
    );
  }
}
