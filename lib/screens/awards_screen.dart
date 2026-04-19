// ============================================================
// awards_screen.dart — achievement badges.
//
// Three badge categories:
//   🔬 Scanner  — scan count milestones (1, 10, 25, 50, 100)
//   🔥 Streaker — daily streak milestones (3, 7, 14, 30)
//   🌱 Grade    — earning high grades (first A, 5× A, 10× A)
//
// Locked badges are dimmed with a lock icon overlay.
// Unlocked badges show the full colour + emoji.
//
// Currently uses hardcoded progress — wire to SharedPreferences
// once state management is in place.
// ============================================================

import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/scan_storage.dart';

// ── Badge data model ─────────────────────────────────────────
class Badge {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;
  final Color color;

  const Badge({
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.color,
  });
}

// ── Screen ───────────────────────────────────────────────────
class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});
  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {
  int _totalScans = 0;
  int _streakDays = 0;
  int _totalAGrades = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await ScanStorage.load();
    setState(() {
      _totalScans = entries.length;
      _streakDays = ScanStorage.computeStreak(entries);
      _totalAGrades = entries.where((e) => e.grade == 'A').length;
    });
  }

  List<Badge> get _scannerBadges => [
    Badge(emoji: '🔭', title: 'First Scan',  description: 'Scan your very first product.', unlocked: _totalScans >= 1,   color: kGold),
    Badge(emoji: '🧪', title: 'Lab Rat',     description: 'Scan 10 products.',             unlocked: _totalScans >= 10,  color: const Color(0xFF4A90B8)),
    Badge(emoji: '🔬', title: 'Researcher',  description: 'Scan 25 products.',             unlocked: _totalScans >= 25,  color: kMoss),
    Badge(emoji: '📊', title: 'Data Nerd',   description: 'Scan 50 products.',             unlocked: _totalScans >= 50,  color: const Color(0xFF7B4EA0)),
    Badge(emoji: '🏆', title: 'Century',     description: 'Scan 100 products.',            unlocked: _totalScans >= 100, color: const Color(0xFFE8A020)),
  ];

  List<Badge> get _streakerBadges => [
    Badge(emoji: '🔥',    title: '3-Day Streak',    description: 'Scan for 3 days in a row.',   unlocked: _streakDays >= 3,  color: const Color(0xFFE86020)),
    Badge(emoji: '⚡',    title: 'Week Warrior',    description: 'Scan for 7 days straight.',   unlocked: _streakDays >= 7,  color: const Color(0xFFD4A020)),
    Badge(emoji: '🧊',    title: 'Ice Keeper',      description: 'Keep a 14-day streak.',       unlocked: _streakDays >= 14, color: const Color(0xFF4A90B8)),
    Badge(emoji: '🐻‍❄️', title: "Nanuk's Champion", description: 'Reach a 30-day streak!',     unlocked: _streakDays >= 30, color: kStreakDark),
  ];

  List<Badge> get _gradeBadges => [
    Badge(emoji: '🌱', title: 'Green Choice',    description: 'Earn your first A-grade scan.', unlocked: _totalAGrades >= 1,  color: kMoss),
    Badge(emoji: '🌿', title: 'Eco Conscious',   description: 'Earn 5 A-grade scans.',         unlocked: _totalAGrades >= 5,  color: kMoss),
    Badge(emoji: '🌳', title: 'Planet Guardian', description: 'Earn 10 A-grade scans.',        unlocked: _totalAGrades >= 10, color: const Color(0xFF2D6B22)),
  ];

  @override
  Widget build(BuildContext context) {
    final allBadges = [..._scannerBadges, ..._streakerBadges, ..._gradeBadges];
    final unlocked = allBadges.where((b) => b.unlocked).length;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACHIEVEMENTS', style: kLabelStyle(size: 11, color: kInkMuted)),
                    const SizedBox(height: 4),
                    Text('Awards', style: kDisplayStyle(size: 32, color: kInk, letterSpacing: -1.0)),
                    const SizedBox(height: 14),
                    _ProgressBar(unlocked: unlocked, total: allBadges.length),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _BadgeSection(title: '🔬  SCANNER',  badges: _scannerBadges),
            _BadgeSection(title: '🔥  STREAKER', badges: _streakerBadges),
            _BadgeSection(title: '🌱  GRADES',   badges: _gradeBadges),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Overall progress bar ──────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int unlocked;
  final int total;
  const _ProgressBar({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInk.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$unlocked / $total unlocked',
                style: kBodyStyle(size: 13, color: kInk, weight: FontWeight.w700),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: kMonoStyle(size: 14, color: kMoss),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 8, color: kInk.withOpacity(0.08)),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(height: 8, color: kMoss),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge section (category) ──────────────────────────────────
class _BadgeSection extends StatelessWidget {
  final String title;
  final List<Badge> badges;
  const _BadgeSection({required this.title, required this.badges});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: kLabelStyle(size: 11, color: kInkMuted)),
            const SizedBox(height: 12),
            ...badges.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BadgeCard(badge: b),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Individual badge card ─────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final Badge badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final locked = !badge.unlocked;

    return AnimatedOpacity(
      opacity: locked ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: locked ? kSurface : badge.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked ? kInk.withOpacity(0.07) : badge.color.withOpacity(0.25),
            width: locked ? 1 : 1.5,
          ),
          boxShadow: locked
              ? []
              : [
                  BoxShadow(
                    color: badge.color.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Emoji in coloured circle (or grey if locked)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: locked
                    ? kInk.withOpacity(0.06)
                    : badge.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    badge.emoji,
                    style: TextStyle(fontSize: locked ? 22 : 26),
                  ),
                  if (locked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: kInkMuted,
                          shape: BoxShape.circle,
                          border: Border.all(color: kSurface, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: kBodyStyle(
                      size: 14,
                      color: locked ? kInkMuted : kInk,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    badge.description,
                    style: kBodyStyle(size: 12, color: kInkMuted),
                  ),
                ],
              ),
            ),
            // Checkmark if unlocked
            if (!locked)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: badge.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
