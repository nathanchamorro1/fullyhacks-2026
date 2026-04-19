// ============================================================
// results_screen.dart — polar-bear-themed scan results.
//
// This is what the user sees right after scanning a product.
// Layout (top → bottom):
//   1. Product header     — image, name, brand
//   2. Big score badge    — circular A-E grade + numeric, color-coded
//   3. Nanuk reacts       — the polar bear's line changes with the score
//   4. Category breakdown — packaging / ingredients / origin / company
//   5. Greener alternatives — scrollable row of alternative-product cards
//   6. Earn-points banner — gamification hook
//
// STANDALONE: this file uses a local `ScanResult` data class + hardcoded
// demo data, so the scan-result-page branch compiles with no
// dependency on other branches' models. When the backend + barcode
// branches merge, swap the demo data for real API responses.
// ============================================================

import 'package:flutter/material.dart';

// ---- Palette (matches home screen) ----
const _iceDeep = Color(0xFF173E6B);
const _iceMid = Color(0xFF4A90B8);
const _iceSoft = Color(0xFFDCEEF7);
const _iceWhite = Color(0xFFF6FAFD);
const _gold = Color(0xFFFFB547);

// ============================================================
// LOCAL DATA MODEL  (temporary — will be replaced by the shared
// Product model once branches merge).
// ============================================================
class ScanResult {
  final String name;
  final String brand;
  final String? imageUrl;
  final int score;        // 0-100
  final String grade;     // "A" .. "E"
  final List<ScoreFactor> breakdown;
  final List<Alternative> alternatives;

  const ScanResult({
    required this.name,
    required this.brand,
    required this.score,
    required this.grade,
    required this.breakdown,
    required this.alternatives,
    this.imageUrl,
  });

  /// Demo data so the screen renders standalone during development.
  factory ScanResult.demo() => const ScanResult(
        name: 'Peanut Butter Chocolate Bar',
        brand: 'SnackCo',
        imageUrl: null,
        score: 42,
        grade: 'D',
        breakdown: [
          ScoreFactor(
            icon: Icons.inventory_2_rounded,
            label: 'Packaging',
            detail: 'Single-use plastic wrapper, not recyclable in most regions.',
            score: 25,
          ),
          ScoreFactor(
            icon: Icons.spa_rounded,
            label: 'Ingredients',
            detail: 'Palm oil linked to deforestation. No organic certification.',
            score: 35,
          ),
          ScoreFactor(
            icon: Icons.public_rounded,
            label: 'Origin',
            detail: 'Ingredients shipped from 3 continents; high transport emissions.',
            score: 40,
          ),
          ScoreFactor(
            icon: Icons.factory_rounded,
            label: 'Company',
            detail: 'No public sustainability pledges or emissions targets.',
            score: 55,
          ),
        ],
        alternatives: [
          Alternative(
            name: 'Fair-Trade Dark Chocolate',
            brand: 'GreenLeaf',
            score: 87,
            reason: 'Recyclable paper wrap + organic cocoa',
          ),
          Alternative(
            name: 'Oat & Almond Bar',
            brand: 'HarvestRoots',
            score: 78,
            reason: 'Local ingredients, compostable wrap',
          ),
          Alternative(
            name: 'Nut Butter Cups',
            brand: 'PurePlant',
            score: 72,
            reason: 'B-Corp certified, no palm oil',
          ),
        ],
      );
}

class ScoreFactor {
  final IconData icon;
  final String label;
  final String detail;
  final int score;
  const ScoreFactor({
    required this.icon,
    required this.label,
    required this.detail,
    required this.score,
  });
}

class Alternative {
  final String name;
  final String brand;
  final int score;
  final String reason;
  const Alternative({
    required this.name,
    required this.brand,
    required this.score,
    required this.reason,
  });
}

// ============================================================
// MAIN SCREEN
// ============================================================
class ResultsScreen extends StatelessWidget {
  final ScanResult result;
  // Non-const so we can fall back to ScanResult.demo() (a factory, which
  // can't run at compile time). Dropping `const` here is a non-issue.
  ResultsScreen({super.key, ScanResult? result})
      : result = result ?? ScanResult.demo();

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(result.score);

    return Scaffold(
      backgroundColor: _iceWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _iceSoft,
            foregroundColor: _iceDeep,
            pinned: true,
            elevation: 0,
            title: const Text(
              'Scan result',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductHeader(result: result),
                  const SizedBox(height: 20),
                  _ScoreBadge(
                    score: result.score,
                    grade: result.grade,
                    color: color,
                  ),
                  const SizedBox(height: 20),
                  _NanukReaction(score: result.score),
                  const SizedBox(height: 24),
                  const _SectionTitle('Why this score'),
                  const SizedBox(height: 10),
                  ...result.breakdown
                      .map((f) => _BreakdownRow(factor: f))
                      .toList(),
                  const SizedBox(height: 24),
                  const _SectionTitle('Greener alternatives'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 178,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: result.alternatives.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          _AlternativeCard(alt: result.alternatives[i]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _PointsBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Green (80+), teal (60-79), amber (40-59), orange (20-39), red (<20).
  static Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF2E7D57);
    if (s >= 60) return const Color(0xFF4A90B8);
    if (s >= 40) return const Color(0xFFFFB547);
    if (s >= 20) return const Color(0xFFEF6C00);
    return const Color(0xFFD84315);
  }
}

// ============================================================
// PRODUCT HEADER — image + name + brand
// ============================================================
class _ProductHeader extends StatelessWidget {
  final ScanResult result;
  const _ProductHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _iceMid.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 76,
              child: result.imageUrl != null
                  ? Image.network(result.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImageFallback())
                  : const _ImageFallback(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _iceDeep,
                  ),
                ),
                if (result.brand.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    result.brand,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _iceSoft,
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_rounded,
          color: _iceMid, size: 34),
    );
  }
}

// ============================================================
// SCORE BADGE — big circular score with grade letter.
// ============================================================
class _ScoreBadge extends StatelessWidget {
  final int score;
  final String grade;
  final Color color;
  const _ScoreBadge({
    required this.score,
    required this.grade,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular grade badge.
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring.
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: _iceSoft,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                // Inner text.
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      grade,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Text(
                      '$score/100',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sustainability',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _headlineForScore(score),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _iceDeep,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subForScore(score),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _headlineForScore(int s) {
    if (s >= 80) return 'Excellent choice';
    if (s >= 60) return 'Pretty good';
    if (s >= 40) return 'Could be better';
    if (s >= 20) return 'Heavy impact';
    return 'Poor choice';
  }

  static String _subForScore(int s) {
    if (s >= 80) return 'This product has strong eco credentials.';
    if (s >= 60) return 'Decent overall — a few areas to watch.';
    if (s >= 40) return 'Mixed signals. Check alternatives below.';
    if (s >= 20) return 'Significant environmental concerns.';
    return 'Major red flags across the board.';
  }
}

// ============================================================
// NANUK'S REACTION — polar bear speaks based on the score.
// ============================================================
class _NanukReaction extends StatelessWidget {
  final int score;
  const _NanukReaction({required this.score});

  String get _line {
    if (score >= 80) return "My ice is refreezing. Thank you!";
    if (score >= 60) return "Not bad! Keep the good picks coming.";
    if (score >= 40) return "Hmm. Maybe try an alternative below?";
    return "Oh no — my ice is melting. Please pick better!";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: _iceSoft, width: 3),
          ),
          alignment: Alignment.center,
          child: const Text('🐻\u200d❄️', style: TextStyle(fontSize: 40)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _iceSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _line,
              style: const TextStyle(
                fontSize: 13.5,
                color: _iceDeep,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _iceDeep,
      ),
    );
  }
}

// ============================================================
// BREAKDOWN ROW — one line per factor (packaging, etc.) with a
// mini progress bar and explanation.
// ============================================================
class _BreakdownRow extends StatelessWidget {
  final ScoreFactor factor;
  const _BreakdownRow({required this.factor});

  @override
  Widget build(BuildContext context) {
    final color = ResultsScreen._scoreColor(factor.score);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _iceSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(factor.icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                factor.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _iceDeep,
                ),
              ),
              const Spacer(),
              Text(
                '${factor.score}/100',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: factor.score / 100,
              minHeight: 6,
              backgroundColor: _iceSoft,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            factor.detail,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ALTERNATIVE CARD — a single "try this instead" card.
// ============================================================
class _AlternativeCard extends StatelessWidget {
  final Alternative alt;
  const _AlternativeCard({required this.alt});

  @override
  Widget build(BuildContext context) {
    final color = ResultsScreen._scoreColor(alt.score);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _iceSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${alt.score}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.eco_rounded, color: _iceMid, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alt.name,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _iceDeep,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            alt.brand,
            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            alt.reason,
            style: const TextStyle(
              fontSize: 11.5,
              color: _iceDeep,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// POINTS BANNER — the gamification hook at the bottom.
// ============================================================
class _PointsBanner extends StatelessWidget {
  const _PointsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_iceMid, _iceDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: _gold, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+10 points earned!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pick a greener alt to earn 2×',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
