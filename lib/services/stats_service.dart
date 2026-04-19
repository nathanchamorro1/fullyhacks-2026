// ============================================================
// stats_service.dart — user stats with instant in-memory cache.
//
// In-memory static state updates immediately so the UI reflects
// changes right away. SharedPreferences persists across sessions.
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

class UserStats {
  final int scanCount;
  final int streakDays;
  final String avgGrade;

  const UserStats({
    required this.scanCount,
    required this.streakDays,
    required this.avgGrade,
  });

  static const empty = UserStats(scanCount: 0, streakDays: 0, avgGrade: '—');
}

class StatsService {
  // ── In-memory cache (updates instantly) ──────────────────
  static int    _scanCount  = 0;
  static int    _streakDays = 0;
  static int    _totalScore = 0;
  static int    _scoreCount = 0;
  static bool   _loaded     = false;

  static const _keyScanCount  = 'nanuk_scan_count';
  static const _keyStreak     = 'nanuk_streak_days';
  static const _keyLastDate   = 'nanuk_last_scan_date';
  static const _keyTotalScore = 'nanuk_total_score';
  static const _keyScoreCount = 'nanuk_score_count';

  /// Load stats — returns instantly from cache after first load.
  Future<UserStats> load() async {
    if (!_loaded) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _scanCount  = prefs.getInt(_keyScanCount)  ?? 0;
        _streakDays = prefs.getInt(_keyStreak)      ?? 0;
        _totalScore = prefs.getInt(_keyTotalScore)  ?? 0;
        _scoreCount = prefs.getInt(_keyScoreCount)  ?? 0;
      } catch (_) { /* first run / web — ignore */ }
      _loaded = true;
    }
    return _build();
  }

  /// Call after every successful scan. Updates cache immediately.
  Future<void> recordScan(int combinedScore) async {
    // Update in-memory state right away
    _scanCount++;
    _totalScore += combinedScore;
    _scoreCount++;

    // Streak logic
    final today     = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    try {
      final prefs    = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(_keyLastDate) ?? '';

      if (lastDate == today) {
        // Already scanned today
      } else if (lastDate == yesterday) {
        _streakDays++;
      } else {
        _streakDays = 1;
      }

      // Persist everything
      await prefs.setInt(_keyScanCount,  _scanCount);
      await prefs.setInt(_keyStreak,     _streakDays);
      await prefs.setString(_keyLastDate, today);
      await prefs.setInt(_keyTotalScore, _totalScore);
      await prefs.setInt(_keyScoreCount, _scoreCount);
    } catch (_) {
      // Web/first run — just keep in-memory streak at 1
      if (_streakDays == 0) _streakDays = 1;
    }
  }

  UserStats _build() {
    final avg = _scoreCount > 0 ? (_totalScore / _scoreCount).round() : -1;
    return UserStats(
      scanCount:  _scanCount,
      streakDays: _streakDays,
      avgGrade:   avg < 0 ? '—' : _grade(avg),
    );
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _grade(int score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 40) return 'D';
    return 'F';
  }
}
