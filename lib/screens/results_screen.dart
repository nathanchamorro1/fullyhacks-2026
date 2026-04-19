// ============================================================
// results_screen.dart — warm, character-driven scan results.
//
// The polar bear is the star. Everything else reacts to him.
//
//   Score  70+   → HAPPY.  Bright sky, snowflakes, solid ice,
//                            smiling bear, confetti sparkles.
//   Score 40–69 → MEH.    Overcast sky, neutral bear, cracked ice.
//   Score  <40  → SAD.    Stormy grey sky, raindrops falling,
//                            broken ice floes, crying bear.
//
// Intentional vibe: chunky, warm, playful. Less medical-chart,
// more children's-book illustration.
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/backend_service.dart';

// ---- Palette aliases (preserve internal references to _ice* for painter) ----
const _creamBG   = kBg;
const _creamCard = kSurface;
const _inkDark   = kInk;
const _inkSoft   = kInkMuted;
const _sunGold   = kGold;
// Score mood colours now come from theme (kMoss / kAmber / kScarlet).
// _happyGreen, _mehAmber, _sadRed removed — use _moodColor() instead.
const _iceBlue = Color(0xFF81D4FA);   // used in water layer only
const _iceDeep = Color(0xFF0288D1);   // used in iceberg painter only
const _water   = Color(0xFF1976D2);   // used in water layer only

// Data model is AnalysisResult from backend_service.dart

// ============================================================
// MOOD — derived from score
// ============================================================
enum _Mood { happy, meh, sad }

_Mood _moodFromScore(int s) {
  if (s >= 70) return _Mood.happy;
  if (s >= 40) return _Mood.meh;
  return _Mood.sad;
}


Color _moodColor(_Mood m) => switch (m) {
      _Mood.happy => kMoss,
      _Mood.meh   => kAmber,
      _Mood.sad   => kScarlet,
    };

String _verdictTitle(_Mood m) => switch (m) {
      _Mood.happy => 'Nanuk approves! 🎉',
      _Mood.meh => 'Hmm... could be better',
      _Mood.sad => 'Nanuk\'s ice is melting 💔',
    };

String _verdictSub(_Mood m) => switch (m) {
      _Mood.happy => 'This product keeps the ice cold.',
      _Mood.meh => 'Not terrible, but Nanuk has opinions.',
      _Mood.sad => 'Please pick something gentler for our home.',
    };

String _nanukLine(_Mood m) => switch (m) {
      _Mood.happy =>
        '"My paws love this choice. The ice stays strong thanks to you."',
      _Mood.meh =>
        '"It\'s okay... but check out the alternatives below — they\'re kinder."',
      _Mood.sad =>
        '"Every one of these melts a little more of my home. Swap it, please?"',
    };

// ============================================================
// MAIN SCREEN
// ============================================================
class ResultsScreen extends StatefulWidget {
  final AnalysisResult result;

  ResultsScreen({super.key, AnalysisResult? result})
      : result = result ?? AnalysisResult.demo();

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodFromScore(widget.result.combinedScore);

    return Scaffold(
      backgroundColor: _creamBG,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: kBg,
            foregroundColor: kInk,
            pinned: true,
            elevation: 0,
            title: Text(
              'SCAN RESULT',
              style: kLabelStyle(size: 13, color: kInk, letterSpacing: 2.0),
            ),
          ),
          // Hero polar bear scene.
          SliverToBoxAdapter(
            child: _MoodScene(mood: mood, animation: _ctrl),
          ),
          // Everything else.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              child: Column(
                // MainAxisSize.min is required here: SliverToBoxAdapter
                // gives children unbounded height, and Column's default
                // max would try to fill infinity → box.dart assertion.
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VerdictCard(result: widget.result, mood: mood),
                  const SizedBox(height: 18),
                  _NanukQuote(mood: mood),
                  const SizedBox(height: 24),
                  _ScoreSplitRow(result: widget.result),
                  const SizedBox(height: 24),
                  if (widget.result.summary.isNotEmpty) ...[
                    const _WarmSectionTitle('Summary'),
                    const SizedBox(height: 10),
                    _SummaryCard(summary: widget.result.summary),
                    const SizedBox(height: 24),
                  ],
                  if (widget.result.flags.isNotEmpty) ...[
                    const _WarmSectionTitle('Watch out for'),
                    const SizedBox(height: 10),
                    _ChipWrap(items: widget.result.flags, color: kScarlet),
                    const SizedBox(height: 24),
                  ],
                  if (widget.result.positives.isNotEmpty) ...[
                    const _WarmSectionTitle('The good stuff'),
                    const SizedBox(height: 10),
                    _ChipWrap(items: widget.result.positives, color: kMoss),
                    const SizedBox(height: 24),
                  ],
                  _PointsBanner(mood: mood),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MOOD SCENE — the hero.
// Sky gradient, ice platform, polar bear with expression,
// animated particles (snow/rain/clouds).
// ============================================================
class _MoodScene extends StatelessWidget {
  final _Mood mood;
  final Animation<double> animation;

  const _MoodScene({required this.mood, required this.animation});

  List<Color> get _skyColors => switch (mood) {
        _Mood.happy => const [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
        _Mood.meh => const [Color(0xFFB0BEC5), Color(0xFFECEFF1)],
        _Mood.sad => const [Color(0xFF546E7A), Color(0xFF90A4AE)],
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _skyColors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _inkDark.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // Everything inside is decorative — IgnorePointer stops the
      // mouse tracker from hit-testing animated children every frame
      // (which caused the mouse_tracker assertion spam on web).
      child: IgnorePointer(
        child: Stack(
          children: [
            // Sun / moon decoration
            Positioned(
              top: 22,
              right: 28,
              child: _Sun(mood: mood),
            ),

            // Animated particles (snow / rain / clouds).
            // LayoutBuilder is OUTSIDE AnimatedBuilder so we only
            // re-measure once, not on every frame.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight - 80; // keep above water
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (_, __) => _ParticleField(
                      mood: mood,
                      t: animation.value,
                      width: w,
                      height: h,
                    ),
                  );
                },
              ),
            ),

            // Water at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 70,
              child: _WaterLayer(mood: mood, animation: animation),
            ),

            // Ice platform + bear (centered bottom)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _IceAndBear(mood: mood, animation: animation),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUN / STORM CLOUD
// ============================================================
class _Sun extends StatelessWidget {
  final _Mood mood;
  const _Sun({required this.mood});

  @override
  Widget build(BuildContext context) {
    return switch (mood) {
      _Mood.happy => Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFFFE082), _sunGold],
            ),
            boxShadow: [
              BoxShadow(
                color: _sunGold.withValues(alpha: 0.55),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      _Mood.meh => const Text('☁️', style: TextStyle(fontSize: 44)),
      _Mood.sad => const Text('⛈️', style: TextStyle(fontSize: 44)),
    };
  }
}

// ============================================================
// PARTICLE FIELD — snow, rain, or drifting clouds.
// Driven by `t` from 0..1 looping.
// width/height are passed in from a LayoutBuilder OUTSIDE the
// AnimatedBuilder so we don't re-measure every frame.
// ============================================================
class _ParticleField extends StatelessWidget {
  final _Mood mood;
  final double t;
  final double width;
  final double height;
  const _ParticleField({
    required this.mood,
    required this.t,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0) return const SizedBox.shrink();

    final rng = math.Random(7);
    final count = mood == _Mood.meh ? 6 : 20;

    final (emoji, baseSize) = switch (mood) {
      _Mood.happy => ('❄️', 14.0),
      _Mood.meh => ('☁️', 22.0),
      _Mood.sad => ('💧', 12.0),
    };

    return Stack(
      children: List.generate(count, (i) {
        final xSeed = rng.nextDouble();
        final phase = rng.nextDouble();
        final speed = 0.5 + rng.nextDouble() * 0.7;
        final sizeJitter = rng.nextDouble();
        final opacityJitter = rng.nextDouble();

        final progress = (t * speed + phase) % 1.0;
        final x = xSeed * (width - 20);
        final y = progress * height;
        final size = baseSize + sizeJitter * 10;
        final opacity = 0.45 + opacityJitter * 0.45;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Text(emoji, style: TextStyle(fontSize: size)),
          ),
        );
      }),
    );
  }
}

// ============================================================
// WATER LAYER — animated ripples at the bottom.
// ============================================================
class _WaterLayer extends StatelessWidget {
  final _Mood mood;
  final Animation<double> animation;
  const _WaterLayer({required this.mood, required this.animation});

  @override
  Widget build(BuildContext context) {
    final color = mood == _Mood.sad
        ? _water
        : (mood == _Mood.meh ? _iceDeep : _iceBlue);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.55), color],
        ),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          final wobble = math.sin(animation.value * 2 * math.pi) * 4;
          return Stack(
            children: [
              Positioned(
                top: 8 + wobble,
                left: 20,
                child: const Text('~', style: TextStyle(color: Colors.white70, fontSize: 18)),
              ),
              Positioned(
                top: 22 - wobble,
                left: 120,
                child: const Text('~', style: TextStyle(color: Colors.white70, fontSize: 22)),
              ),
              Positioned(
                top: 14 + wobble,
                right: 40,
                child: const Text('~', style: TextStyle(color: Colors.white70, fontSize: 20)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// ICE + BEAR
// Happy: solid wide platform, smiling bear, sparkles.
// Meh:   cracked platform, bear with neutral face.
// Sad:   two small broken floes, crying bear drifting (wobble).
// ============================================================
class _IceAndBear extends StatelessWidget {
  final _Mood mood;
  final Animation<double> animation;

  const _IceAndBear({required this.mood, required this.animation});

  @override
  Widget build(BuildContext context) {
    // Slow wobble effect — bigger for sad (drifting).
    final wobbleAmount = switch (mood) {
      _Mood.happy => 0.0,
      _Mood.meh => 2.0,
      _Mood.sad => 6.0,
    };

    // Passing the static content as `child` tells AnimatedBuilder
    // to NOT rebuild it every frame — only the Transform wrapper
    // recomputes. Cheaper + fewer layout passes.
    return AnimatedBuilder(
      animation: animation,
      child: _IceSceneContent(mood: mood),
      builder: (_, child) {
        final wobble =
            math.sin(animation.value * 2 * math.pi) * wobbleAmount;
        return Transform.translate(
          offset: Offset(wobble, 0),
          child: child,
        );
      },
    );
  }
}

class _IceSceneContent extends StatelessWidget {
  final _Mood mood;
  const _IceSceneContent({required this.mood});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The bear + expression
        _PolarBear(mood: mood),
        // The ice platform under the bear
        _IcePlatform(mood: mood),
      ],
    );
  }
}

// ============================================================
// POLAR BEAR — emoji + mood expression floating near face.
// ============================================================
class _PolarBear extends StatelessWidget {
  final _Mood mood;
  const _PolarBear({required this.mood});

  @override
  Widget build(BuildContext context) {
    // Expression badge that sits near the bear's face.
    final String badge = switch (mood) {
      _Mood.happy => '✨',
      _Mood.meh => '😕',
      _Mood.sad => '😢',
    };

    return SizedBox(
      width: 160,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The bear itself
          const Text('🐻\u200d❄️', style: TextStyle(fontSize: 90)),

          // Expression badge top-right
          Positioned(
            top: 4,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(badge, style: const TextStyle(fontSize: 24)),
            ),
          ),

          // Extra flair for happy: floating hearts
          if (mood == _Mood.happy)
            const Positioned(
              top: 20,
              left: 12,
              child: Text('💙', style: TextStyle(fontSize: 22)),
            ),

          // Extra flair for sad: tear drop trail
          if (mood == _Mood.sad) ...[
            const Positioned(
              bottom: 22,
              left: 62,
              child: Text('💧', style: TextStyle(fontSize: 16)),
            ),
            const Positioned(
              bottom: 8,
              left: 70,
              child: Text('💧', style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ICE PLATFORM — solid block or broken floes.
// ============================================================
class _IcePlatform extends StatelessWidget {
  final _Mood mood;
  const _IcePlatform({required this.mood});

  @override
  Widget build(BuildContext context) {
    // Return tightly-sized widgets so a parent Column with
    // mainAxisSize.min doesn't choke on infinite-width children.
    return switch (mood) {
      _Mood.happy => _IceBlock(width: 260, tilt: 0),
      _Mood.meh => SizedBox(
          width: 220,
          height: 46,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _IceBlock(width: 220, tilt: 0),
              // Crack line running down from a peak.
              Positioned(
                bottom: 2,
                child: Container(
                  width: 2,
                  height: 20,
                  color: _inkDark.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      _Mood.sad => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IceBlock(width: 90, tilt: -0.12),
            const SizedBox(width: 18),
            _IceBlock(width: 110, tilt: 0.08),
          ],
        ),
    };
  }
}

class _IceBlock extends StatelessWidget {
  final double width;
  final double tilt;
  const _IceBlock({required this.width, required this.tilt});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: CustomPaint(
        size: Size(width, 42),
        painter: const _IcebergPainter(),
      ),
    );
  }
}

// Paints a faceted iceberg with jagged peaks, snow caps, and facet
// lines. Shape is normalized to the canvas size so it scales for any
// width the caller supplies.
class _IcebergPainter extends CustomPainter {
  const _IcebergPainter();

  // Peak outline as fractions of (width, height). We trace the silhouette
  // starting from the left waterline, up over jagged peaks, back down to
  // the right waterline, then across the flat bottom.
  static const _silhouette = <Offset>[
    Offset(0.00, 0.62), // left base
    Offset(0.06, 0.40), // up toward first peak
    Offset(0.12, 0.18), // ↗ peak 1
    Offset(0.19, 0.08), // peak 1 top
    Offset(0.24, 0.26), // valley
    Offset(0.32, 0.04), // peak 2 (tallest)
    Offset(0.40, 0.30), // valley
    Offset(0.48, 0.14), // peak 3
    Offset(0.55, 0.24), // valley
    Offset(0.64, 0.06), // peak 4
    Offset(0.72, 0.22), // valley
    Offset(0.82, 0.32), // back down
    Offset(0.92, 0.50),
    Offset(1.00, 0.66), // right base
    Offset(1.00, 1.00), // bottom-right
    Offset(0.00, 1.00), // bottom-left
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ---- Build the main silhouette path ----
    final body = Path();
    body.moveTo(_silhouette.first.dx * w, _silhouette.first.dy * h);
    for (final p in _silhouette.skip(1)) {
      body.lineTo(p.dx * w, p.dy * h);
    }
    body.close();

    // ---- Soft shadow just underneath (gives it depth) ----
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(
      body,
      Paint()
        ..color = _iceDeep.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();

    // ---- Main iceberg fill (cool gradient top→bottom) ----
    final bodyGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFAFEFF), // almost-white highlight up top
        Color(0xFFDBF0FB),
        Color(0xFFA2D8F2),
        Color(0xFF4FC3F7), // deeper cyan near water
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    );
    canvas.drawPath(
      body,
      Paint()..shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ---- Snow caps on each peak ----
    final snow = Paint()..color = Colors.white.withValues(alpha: 0.92);
    _drawCap(canvas, snow, w, h, peakX: 0.19, peakY: 0.08, spread: 0.055);
    _drawCap(canvas, snow, w, h, peakX: 0.32, peakY: 0.04, spread: 0.06);
    _drawCap(canvas, snow, w, h, peakX: 0.48, peakY: 0.14, spread: 0.05);
    _drawCap(canvas, snow, w, h, peakX: 0.64, peakY: 0.06, spread: 0.055);

    // ---- Facet lines — subtle cracks running down from peaks ----
    final facet = Paint()
      ..color = _iceDeep.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0.19 * w, 0.08 * h), Offset(0.21 * w, 0.70 * h), facet);
    canvas.drawLine(
        Offset(0.32 * w, 0.04 * h), Offset(0.36 * w, 0.80 * h), facet);
    canvas.drawLine(
        Offset(0.48 * w, 0.14 * h), Offset(0.52 * w, 0.72 * h), facet);
    canvas.drawLine(
        Offset(0.64 * w, 0.06 * h), Offset(0.66 * w, 0.74 * h), facet);

    // ---- White outline on top edges (crisp snow rim) ----
    final rim = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final rimPath = Path();
    rimPath.moveTo(_silhouette.first.dx * w, _silhouette.first.dy * h);
    // only the top silhouette (skip the flat bottom two points)
    for (final p in _silhouette.sublist(1, _silhouette.length - 2)) {
      rimPath.lineTo(p.dx * w, p.dy * h);
    }
    canvas.drawPath(rimPath, rim);
  }

  // Draws a small white triangular cap centered on a peak point.
  void _drawCap(
    Canvas canvas,
    Paint paint,
    double w,
    double h, {
    required double peakX,
    required double peakY,
    required double spread,
  }) {
    final cap = Path()
      ..moveTo((peakX - spread) * w, (peakY + 0.06) * h)
      ..lineTo(peakX * w, peakY * h)
      ..lineTo((peakX + spread) * w, (peakY + 0.06) * h)
      ..close();
    canvas.drawPath(cap, paint);
  }

  @override
  bool shouldRepaint(covariant _IcebergPainter oldDelegate) => false;
}

// ============================================================
// VERDICT CARD — score is the hero. Big circular gauge with
// the number in the center, then verdict headline underneath.
// ============================================================
class _VerdictCard extends StatelessWidget {
  final AnalysisResult result;
  final _Mood mood;
  const _VerdictCard({required this.result, required this.mood});

  @override
  Widget build(BuildContext context) {
    final color = _moodColor(mood);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      decoration: BoxDecoration(
        color: _creamCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ---- HERO SCORE GAUGE ----
          _ScoreGauge(
            score: result.combinedScore,
            grade: result.grade,
            color: color,
          ),
          const SizedBox(height: 20),

          // ---- VERDICT TITLE ----
          Text(
            _verdictTitle(mood),
            textAlign: TextAlign.center,
            style: kDisplayStyle(size: 22, color: kInk, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            _verdictSub(mood),
            textAlign: TextAlign.center,
            style: kBodyStyle(size: 14, color: kInkMuted),
          ),
          const SizedBox(height: 20),

          // ---- PRODUCT INFO FOOTER ----
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _creamBG,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🛒', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.productName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _inkDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (result.brand.isNotEmpty)
                        Text(
                          result.brand,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCORE GAUGE — the star of the whole results page.
// Circular ring with a mood-colored progress arc + HUGE number
// in the middle + grade pill underneath.
// ============================================================
class _ScoreGauge extends StatelessWidget {
  final int score;
  final String grade;
  final Color color;
  const _ScoreGauge({
    required this.score,
    required this.grade,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft mood-colored glow behind the gauge.
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.0),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),

          // The arc itself.
          CustomPaint(
            size: const Size(200, 200),
            painter: _ScoreArcPainter(score: score, color: color),
          ),

          // Center content — score + /100 + grade pill.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 0.95,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'out of 100',
                style: TextStyle(
                  fontSize: 11,
                  color: _inkSoft,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'GRADE $grade',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ScoreDots(score: score, size: 11, spacing: 6),
            ],
          ),
        ],
      ),
    );
  }
}

// Paints the score gauge: a full background ring + a colored
// progress arc covering `score / 100` of the circle, starting
// from the top (12 o'clock) and moving clockwise.
class _ScoreArcPainter extends CustomPainter {
  final int score;
  final Color color;
  const _ScoreArcPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring — soft neutral so the progress arc pops.
    final bg = Paint()
      ..color = _inkSoft.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bg);

    // Colored progress arc.
    final progress = (score.clamp(0, 100)) / 100.0;
    final sweep = progress * 2 * math.pi;
    if (sweep <= 0) return;

    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [color.withValues(alpha: 0.55), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter old) =>
      old.score != score || old.color != color;
}

// ============================================================
// NANUK QUOTE — rounded warm speech bubble.
// ============================================================
class _NanukQuote extends StatelessWidget {
  final _Mood mood;
  const _NanukQuote({required this.mood});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _creamCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _sunGold.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _creamBG,
              border: Border.all(color: _sunGold.withValues(alpha: 0.3), width: 2),
            ),
            alignment: Alignment.center,
            child: const Text('🐻\u200d❄️', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _nanukLine(mood),
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: _inkDark,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================
class _WarmSectionTitle extends StatelessWidget {
  final String text;
  const _WarmSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.toUpperCase(),
            style: kLabelStyle(size: 11, color: kInkMuted),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCORE SPLIT ROW — health vs sustainability side by side
// ============================================================
class _ScoreSplitRow extends StatelessWidget {
  final AnalysisResult result;
  const _ScoreSplitRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScoreTile(
          label: 'HEALTH',
          score: result.healthScore,
          outOf: 10,
          icon: Icons.favorite_rounded,
        ),
        const SizedBox(width: 12),
        _ScoreTile(
          label: 'SUSTAINABILITY',
          score: result.sustainabilityScore,
          outOf: 10,
          icon: Icons.eco_rounded,
        ),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final int score;
  final int outOf;
  final IconData icon;
  const _ScoreTile({
    required this.label,
    required this.score,
    required this.outOf,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct   = score / outOf;
    final color = scoreColor((pct * 100).round());

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scoreBg((pct * 100).round()),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(label, style: kLabelStyle(size: 9, color: color)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$score', style: kMonoStyle(size: 30, color: color)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 3),
                  child: Text('/$outOf',
                      style: kLabelStyle(size: 11, color: color.withValues(alpha: 0.6))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(children: [
                Container(height: 5, color: color.withValues(alpha: 0.15)),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(height: 5, color: color),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================
class _SummaryCard extends StatelessWidget {
  final String summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _creamCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _inkDark.withValues(alpha: 0.07)),
      ),
      child: Text(summary, style: kBodyStyle(size: 14, color: _inkDark)),
    );
  }
}

// ============================================================
// CHIP WRAP — flags or positives as pill chips
// ============================================================
class _ChipWrap extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _ChipWrap({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.30)),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ============================================================
// POINTS BANNER — warm, mood-aware.
// ============================================================
class _PointsBanner extends StatelessWidget {
  final _Mood mood;
  const _PointsBanner({required this.mood});

  @override
  Widget build(BuildContext context) {
    final pts = mood == _Mood.happy ? 20 : 10;
    final msg = mood == _Mood.happy
        ? 'Great pick! Bonus points for keeping Nanuk happy.'
        : 'Earn 2× points when you pick a kinder swap above.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE0B2), Color(0xFFFFD180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: const Text('🏆', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+$pts POINTS EARNED!',
                  style: kDisplayStyle(size: 16, color: kInk, letterSpacing: 0.5),
                ),
                const SizedBox(height: 3),
                Text(
                  msg,
                  style: kBodyStyle(size: 12, color: kInkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
