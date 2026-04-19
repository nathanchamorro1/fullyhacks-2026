// ============================================================
// awards_screen.dart — dynamic achievement badges.
//
// Loads real stats from StatsService on every visit.
// Three badge categories:
//   🔬 Scanner  — scan count milestones (1, 10, 25, 50, 100)
//   🔥 Streaker — daily streak milestones (3, 7, 14, 30)
//   🌱 Grades   — A-grade scan count (1, 5, 10)
// ============================================================

import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/stats_service.dart';

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

// ── Badge builders — called with live stats ───────────────────
List<Badge> _buildScannerBadges(int scans) => [
  Badge(
    emoji: '🔭',
    title: 'First Scan',
    description: 'Scan your very first product.',
    unlocked: scans >= 1,
    color: kGold,
  ),
  Badge(
    emoji: '🧪',
    title: 'Lab Rat',
    description: 'Scan 10 products.',
    unlocked: scans >= 10,
    color: kBlue,
  ),
  Badge(
    emoji: '🔬',
    title: 'Researcher',
    description: 'Scan 25 products.',
    unlocked: scans >= 25,
    color: kMoss,
  ),
  Badge(
    emoji: '📊',
    title: 'Data Nerd',
    description: 'Scan 50 products.',
    unlocked: scans >= 50,
    color: const Color(0xFF7B4EA0),
  ),
  Badge(
    emoji: '🏆',
    title: 'Century',
    description: 'Scan 100 products.',
    unlocked: scans >= 100,
    color: const Color(0xFFE8A020),
  ),
];

List<Badge> _buildStreakerBadges(int streak) => [
  Badge(
    emoji: '🔥',
    title: '3-Day Streak',
    description: 'Scan for 3 days in a row.',
    unlocked: streak >= 3,
    color: const Color(0xFFE86020),
  ),
  Badge(
    emoji: '⚡',
    title: 'Week Warrior',
    description: 'Scan for 7 days straight.',
    unlocked: streak >= 7,
    color: const Color(0xFFD4A020),
  ),
  Badge(
    emoji: '🧊',
    title: 'Ice Keeper',
    description: 'Keep a 14-day streak.',
    unlocked: streak >= 14,
    color: kBlue,
  ),
  Badge(
    emoji: '🐻‍❄️',
    title: "Nanuk's Champion",
    description: 'Reach a 30-day streak!',
    unlocked: streak >= 30,
    color: kStreakDark,
  ),
];

List<Badge> _buildGradeBadges(int aGrades) => [
  Badge(
    emoji: '🌱',
    title: 'Green Choice',
    description: 'Earn your first A-grade scan.',
    unlocked: aGrades >= 1,
    color: kMoss,
  ),
  Badge(
    emoji: '🌿',
    title: 'Eco Conscious',
    description: 'Earn 5 A-grade scans.',
    unlocked: aGrades >= 5,
    color: kMoss,
  ),
  Badge(
    emoji: '🌳',
    title: 'Planet Guardian',
    description: 'Earn 10 A-grade scans.',
    unlocked: aGrades >= 10,
    color: const Color(0xFF2D6B22),
  ),
];

// ── Screen ────────────────────────────────────────────────────
class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {
  final _statsService = StatsService();
  UserStats _stats = UserStats.empty;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _statsService.load();
    if (mounted) setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    final scannerBadges  = _buildScannerBadges(_stats.scanCount);
    final streakerBadges = _buildStreakerBadges(_stats.streakDays);
    final gradeBadges    = _buildGradeBadges(_stats.aGradeCount);

    final allBadges      = [...scannerBadges, ...streakerBadges, ...gradeBadges];
    final totalUnlocked  = allBadges.where((b) => b.unlocked).length;
    final totalBadges    = allBadges.length;

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
                    Text(
                      'Awards',
                      style: kDisplayStyle(size: 32, color: kInk, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 14),
                    _ProgressBar(unlocked: totalUnlocked, total: totalBadges),
                    const SizedBox(height: 8),
                    // Live stats summary
                    _StatsSummary(stats: _stats),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _BadgeSection(title: '🔬  SCANNER',  badges: scannerBadges),
            _BadgeSection(title: '🔥  STREAKER', badges: streakerBadges),
            _BadgeSection(title: '🌱  GRADES',   badges: gradeBadges),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Stats summary strip ───────────────────────────────────────
class _StatsSummary extends StatelessWidget {
  final UserStats stats;
  const _StatsSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniStat(label: 'SCANS',   value: '${stats.scanCount}',   icon: Icons.qr_code_rounded,              color: kBlue),
        const SizedBox(width: 8),
        _MiniStat(label: 'STREAK',  value: '${stats.streakDays}d', icon: Icons.local_fire_department_rounded, color: const Color(0xFFE86020)),
        const SizedBox(width: 8),
        _MiniStat(label: 'A GRADES', value: '${stats.aGradeCount}', icon: Icons.eco_rounded,                  color: kMoss),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(value, style: kMonoStyle(size: 14, color: color)),
            const SizedBox(width: 4),
            Text(label, style: kLabelStyle(size: 8, color: color.withOpacity(0.70))),
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
            // Emoji in coloured circle (grey if locked)
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
