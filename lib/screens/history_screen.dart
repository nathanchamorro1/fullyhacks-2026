// ============================================================
// history_screen.dart — scan history list.
//
// Shows every product the user has scanned, most recent first.
// Each row uses Nathan's 3-dot score system + monospace grade.
//
// Data source: SharedPreferences (JSON list). For now ships
// with demo entries so the UI is visible — swap for real data
// once the backend and state management are wired.
// ============================================================

import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/scan_storage.dart';

// ── Data model for a saved scan entry ───────────────────────
class HistoryEntry {
  final String productName;
  final String brand;
  final int score;          // 0-100 combined
  final String grade;       // A-F letter
  final DateTime scannedAt;

  const HistoryEntry({
    required this.productName,
    required this.brand,
    required this.score,
    required this.grade,
    required this.scannedAt,
  });
}


// ── Screen ───────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scans = await ScanStorage.load();
    setState(() {
      _entries = scans.map((e) => HistoryEntry(
        productName: e.name,
        brand: e.brand,
        score: e.score,
        grade: e.grade,
        scannedAt: e.scannedAt,
      )).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryHeader(entries: _entries),
            Expanded(
              child: _entries.isEmpty
                  ? _EmptyState()
                  : _HistoryList(entries: _entries),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────
class _HistoryHeader extends StatelessWidget {
  final List<HistoryEntry> entries;
  const _HistoryHeader({required this.entries});
  int get entryCount => entries.length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page label
          Text('SCAN HISTORY', style: kLabelStyle(size: 11, color: kInkMuted)),
          const SizedBox(height: 4),
          // Bold title
          Text(
            'Your Scans',
            style: kDisplayStyle(size: 32, color: kInk, letterSpacing: -1.0),
          ),
          const SizedBox(height: 12),
          // Summary strip
          _SummaryStrip(entries: entries),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Compact summary: total scans, avg score, best grade
class _SummaryStrip extends StatelessWidget {
  final List<HistoryEntry> entries;
  const _SummaryStrip({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final avgScore = entries.isEmpty
        ? 0
        : (entries.map((e) => e.score).reduce((a, b) => a + b) / entries.length)
            .round();
    final bestScore = entries.map((e) => e.score).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kInk.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Strip(label: 'TOTAL', value: '${entries.length}', color: kInk),
          _StripDivider(),
          _Strip(
            label: 'AVG SCORE',
            value: '$avgScore',
            color: scoreColor(avgScore),
          ),
          _StripDivider(),
          _Strip(
            label: 'BEST',
            value: '$bestScore',
            color: scoreColor(bestScore),
          ),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Strip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: kMonoStyle(size: 22, color: color)),
        const SizedBox(height: 2),
        Text(label, style: kLabelStyle(size: 9, color: kInkMuted)),
      ],
    );
  }
}

class _StripDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: kInk.withOpacity(0.08));
  }
}

// ── Scrollable list ───────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  final List<HistoryEntry> entries;
  const _HistoryList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _HistoryCard(entry: entries[i]),
    );
  }
}

// ── Individual history card ───────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryCard({required this.entry});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(entry.score);
    final bg    = scoreBg(entry.score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInk.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.grade,
                  style: kMonoStyle(size: 16, color: color),
                ),
                const SizedBox(height: 2),
                ScoreDots(score: entry.score, size: 6, spacing: 2),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Name + brand
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.productName,
                  style: kBodyStyle(
                      size: 14, color: kInk, weight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  entry.brand,
                  style: kBodyStyle(size: 12, color: kInkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Score + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: kMonoStyle(size: 20, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                _timeAgo(entry.scannedAt),
                style: kLabelStyle(size: 9, color: kInkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐻‍❄️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            Text(
              'No scans yet',
              style: kDisplayStyle(size: 24, color: kInk, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scanning products to see your history here.',
              style: kBodyStyle(size: 14, color: kInkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
