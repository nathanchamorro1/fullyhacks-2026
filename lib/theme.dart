// ============================================================
// theme.dart — shared palette + text-style helpers for Nanuk.
//
// Visual DNA: Nathan's brutalist-bold type, black/white/blue palette.
//
//   Background : warm paper cream  #F4EFE6
//   Ink        : near-black        #0C0C0C
//   Blue       : glacier blue      #4A90B8  ← primary accent
//   Blue Dark  : arctic navy       #173E6B
//   Blue Soft  : ice tint bg       #EBF4FA
//
//   Scores (unchanged — green/amber/red):
//   Moss       : good  70-100      #3A6B30
//   Amber      : mid   40-69       #B86E00
//   Scarlet    : bad    0-39       #B82222
// ============================================================

import 'package:flutter/material.dart';

// ── Background / surface ─────────────────────────────────────────────────
const kBg          = Color(0xFFF4EFE6);   // warm paper
const kSurface     = Color(0xFFFFFFFF);   // card white
const kSurfaceWarm = Color(0xFFFFFBF4);   // slightly warmer card

// ── Ink ──────────────────────────────────────────────────────────────────
const kInk         = Color(0xFF0C0C0C);   // display text
const kInkMuted    = Color(0xFF6B6B6B);   // secondary text
const kInkLight    = Color(0xFFAAAAAA);   // placeholder / disabled

// ── Blue accent (replaces gold as primary brand colour) ──────────────────
const kBlue        = Color(0xFF4A90B8);   // glacier blue
const kBlueDark    = Color(0xFF173E6B);   // arctic night navy
const kBlueSoft    = Color(0xFFEBF4FA);   // ice-tinted background
const kBlueLight   = Color(0xFFB3D9F0);   // medium-light blue

// ── Gold — kept only for warm touches (bear, results screen) ─────────────
const kGold        = Color(0xFFFFB547);
const kGoldSoft    = Color(0xFFFFF3DC);

// ── Score colours (Nathan's system) ──────────────────────────────────────
const kMoss        = Color(0xFF3A6B30);   // 70-100  good
const kMossBg      = Color(0xFFDDEDD9);
const kAmber       = Color(0xFFB86E00);   // 40-69   mid
const kAmberBg     = Color(0xFFFFF0D4);
const kScarlet     = Color(0xFFB82222);   // 0-39    bad
const kScarletBg   = Color(0xFFFFE0E0);

// ── Streak ribbon ────────────────────────────────────────────────────────
const kStreakDark  = Color(0xFF1B3A18);
const kStreakText  = Color(0xFFB8F0A8);

// ── Helper: colour for a 0-100 score ────────────────────────────────────
Color scoreColor(int score) {
  if (score >= 70) return kMoss;
  if (score >= 40) return kAmber;
  return kScarlet;
}

Color scoreBg(int score) {
  if (score >= 70) return kMossBg;
  if (score >= 40) return kAmberBg;
  return kScarletBg;
}

String scoreLabel(int score) {
  if (score >= 70) return 'GOOD';
  if (score >= 40) return 'MEH';
  return 'BAD';
}

// ── Nathan's 3-dot score widget ──────────────────────────────────────────
class ScoreDots extends StatelessWidget {
  final int score;
  final double size;
  final double spacing;
  const ScoreDots({
    super.key,
    required this.score,
    this.size = 9,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    final color  = scoreColor(score);
    final filled = score >= 70 ? 3 : score >= 40 ? 2 : 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Container(
        width: size,
        height: size,
        margin: EdgeInsets.only(right: i < 2 ? spacing : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < filled ? color : color.withOpacity(0.18),
        ),
      )),
    );
  }
}

// ── Typography helpers ───────────────────────────────────────────────────

TextStyle kDisplayStyle({
  double size = 48,
  Color color = kInk,
  double letterSpacing = -1.5,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: letterSpacing,
      height: 1.0,
    );

TextStyle kLabelStyle({
  double size = 11,
  Color color = kInkMuted,
  double letterSpacing = 1.8,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: letterSpacing,
    );

TextStyle kMonoStyle({
  double size = 28,
  Color color = kInk,
  FontWeight weight = FontWeight.w900,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.5,
    );

TextStyle kBodyStyle({
  double size = 14,
  Color color = kInkMuted,
  FontWeight weight = FontWeight.w500,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
